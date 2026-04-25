<?php

namespace App\Ai\Tools;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use App\Support\PlanPayload;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use InvalidArgumentException;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class EditSchedule implements Tool
{
    public function __construct(
        private User $user,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string
    {
        $easy = TrainingType::Easy->value;
        $longRun = TrainingType::LongRun->value;
        $distanceCsv = '"'.implode('", "', GoalDistance::values()).'"';
        $distanceExample = GoalDistance::HalfMarathon->value;

        return <<<DESC
        Apply surgical edits to a plan - either an existing proposal (pending or rejected) OR the runner's active plan. Returns a revised proposal for runner approval. USE THIS instead of `create_schedule` for any tweak; much cheaper and faster than rebuilding the whole plan.

        Target selection (automatic when neither id is passed):
        1. If `proposal_id` is set: edit that proposal.
        2. If `goal_id` is set: edit that active Goal's schedule in place.
        3. Otherwise: pick the latest pending proposal; if none, fall back to the active Goal; if neither, fall back to the most recent proposal of any status.

        Covers: changing specific days (pace, distance, type, title, description, intervals, HR zone), dropping a day, adding a day, shifting a day to a different weekday, and updating goal metadata (distance, target_date, goal_time_seconds, goal_name, preferred_weekdays, additional_notes).

        `operations` is a JSON-encoded array of ops. Shapes:
        - `{"op":"set_day","week":1,"day_of_week":6,"fields":{"type":"{$longRun}","target_km":18,"target_pace_seconds_per_km":360}}` - update fields on one day
        - `{"op":"remove_day","week":2,"day_of_week":3}` - delete a day
        - `{"op":"add_day","week":2,"day_of_week":3,"fields":{"type":"{$easy}","title":"Easy Run","target_km":5,"target_pace_seconds_per_km":390,"target_heart_rate_zone":2}}` - add a day (fails if one already exists on that weekday)
        - `{"op":"shift_day","week":3,"from_day_of_week":2,"to_day_of_week":4}` - move a day to a different weekday
        - `{"op":"set_goal","fields":{"distance":"{$distanceExample}","target_date":"2026-09-15","goal_time_seconds":6300,"preferred_weekdays":[2,4,6],"goal_name":"Half PR","additional_notes":"left knee sensitive"}}` - update goal metadata. `distance` must be a GoalDistance enum value (one of: {$distanceCsv}), NOT a meter count.

        Use `create_schedule` ONLY for fundamental rebuilds (different goal type, completely new structure). For every other change, use `edit_schedule`. To change `goal_type` or the runner's `coach_style`, use `create_schedule` - those are out of scope for edits.

        After your ops run: weekly km totals, day titles, and paces (for days you didn't explicitly set) are recomputed from the runner's Strava baseline, and `target_date` is aligned to the final training day. Past training days are preserved untouched; only days from today onward are modified when editing an active plan.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'proposal_id' => $schema->integer()->required()->nullable()->description('Proposal to edit. Null + null goal_id = auto-detect (prefer pending proposal, fall back to active plan).'),
            'goal_id' => $schema->integer()->required()->nullable()->description('Active Goal to edit in place. Pass null to auto-detect. Pass this when the runner has an ACTIVE plan and no pending proposal.'),
            'operations' => $schema->string()->required()->description('JSON-encoded array of operations. See tool description for op formats. Must contain at least one op.'),
        ];
    }

    public function handle(Request $request): string
    {
        $proposalId = $request['proposal_id'] ?? null;
        $goalId = $request['goal_id'] ?? null;

        if ($proposalId !== null && $goalId !== null) {
            return json_encode(['error' => 'Pass either proposal_id or goal_id, not both.']);
        }

        $opsRaw = $request['operations'] ?? null;
        $ops = is_string($opsRaw) ? json_decode($opsRaw, true) : null;
        if (! is_array($ops) || count($ops) === 0) {
            return json_encode(['error' => 'operations must be a non-empty JSON-encoded array.']);
        }

        // Resolve target: (payload, responseProposalType, extraMeta)
        $resolved = $this->resolveTarget($proposalId, $goalId);
        if (is_string($resolved)) {
            return $resolved; // pre-encoded error JSON
        }

        [$payload, $responseProposalType] = $resolved;

        foreach ($ops as $i => $op) {
            if (! is_array($op)) {
                return json_encode([
                    'error' => "Operation #{$i} must be a JSON object.",
                    'plan_structure' => PlanPayload::weekStructure($payload),
                ]);
            }
            try {
                $payload = $this->apply($payload, $op);
            } catch (InvalidArgumentException $e) {
                // Include the current plan structure so the agent can see
                // what weeks/days actually exist and retry with a valid op
                // instead of guessing day_of_week values.
                return json_encode([
                    'error' => "Operation #{$i}: ".$e->getMessage(),
                    'plan_structure' => PlanPayload::weekStructure($payload),
                ]);
            }
        }

        // Verify+optimize pass: recompute weekly totals, regenerate titles
        // and paces for any day that didn't already have them, reclassify
        // long runs. `alignRaceDay: false` because edits shouldn't stomp
        // user-set target_date changes (set_goal op) or rename the final
        // day to the goal name — both of those are CreateSchedule-only
        // behaviours. Explicit user paces/titles survive.
        $payload = $this->optimizer->optimize($payload, $this->user, alignRaceDay: false);

        // Only attach a `diff` when editing a plan the runner has already
        // ACCEPTED (active goal). That's the only case where "N changes to
        // your plan" is meaningful UX. Edits to a still-pending proposal
        // (verify-loop fixups during onboarding, or mid-chat tweaks before
        // the runner has accepted) must NOT carry a diff — the runner
        // never saw the pre-edit version, so showing a "revision" card
        // is confusing (this was the onboarding-shows-"Plan revision" bug).
        if ($responseProposalType === ProposalType::EditActivePlan) {
            $payload['diff'] = array_values($ops);
        } else {
            unset($payload['diff']);
        }

        // Persist the edited plan IMMEDIATELY as a new pending proposal
        // so the next tool in the agent loop (verify_plan auto-target)
        // sees this revision, not the version before the ops were applied.
        $proposal = $this->proposals->persistPending(
            $this->user,
            $responseProposalType,
            $payload,
        );

        // Full payload omitted intentionally — see CreateSchedule::handle
        // for the rationale (conversation-history bloat vs rate limits).
        // `plan_structure` is enough for the agent to compose follow-up
        // ops; `verify_plan` and the UI read the full plan from the DB.
        return json_encode([
            'requires_approval' => true,
            'proposal_type' => $responseProposalType->value,
            'proposal_id' => $proposal->id,
            'plan_structure' => PlanPayload::weekStructure($payload),
        ]);
    }

    /**
     * @return array{0: array<string, mixed>, 1: ProposalType}|string Tuple on success, error JSON string on failure.
     */
    private function resolveTarget(?int $proposalId, ?int $goalId): array|string
    {
        // Explicit proposal
        if ($proposalId !== null) {
            $proposal = CoachProposal::where('user_id', $this->user->id)->find($proposalId);
            if (! $proposal) {
                return json_encode(['error' => 'Proposal not found.']);
            }

            return $this->resolveFromProposal($proposal);
        }

        // Explicit active Goal
        if ($goalId !== null) {
            $goal = Goal::where('user_id', $this->user->id)->find($goalId);
            if (! $goal) {
                return json_encode(['error' => 'Goal not found.']);
            }
            if ($goal->status !== GoalStatus::Active) {
                return json_encode(['error' => "Goal is not active (status = {$goal->status->value}). Only active goals can be edited in place."]);
            }

            return [PlanPayload::fromGoal($goal), ProposalType::EditActivePlan];
        }

        // Auto: pending proposal wins
        $pending = CoachProposal::where('user_id', $this->user->id)
            ->where('status', ProposalStatus::Pending)
            ->latest('id')
            ->first();
        if ($pending) {
            return $this->resolveFromProposal($pending);
        }

        // Then active Goal
        $activeGoal = $this->user->goals()->where('status', GoalStatus::Active)->latest('id')->first();
        if ($activeGoal) {
            return [PlanPayload::fromGoal($activeGoal), ProposalType::EditActivePlan];
        }

        // Fallback: latest any-status proposal (covers reject-then-adjust onboarding flow)
        $latest = CoachProposal::where('user_id', $this->user->id)->latest('id')->first();
        if ($latest) {
            return $this->resolveFromProposal($latest);
        }

        return json_encode(['error' => 'No proposal or active plan found to edit.']);
    }

    /**
     * @return array{0: array<string, mixed>, 1: ProposalType}|string
     */
    private function resolveFromProposal(CoachProposal $proposal): array|string
    {
        if ($proposal->type !== ProposalType::CreateSchedule) {
            return json_encode(['error' => "edit_schedule only edits create_schedule proposals; this proposal is '{$proposal->type->value}'."]);
        }
        if ($proposal->status === ProposalStatus::Accepted) {
            return json_encode(['error' => 'This proposal is already accepted. Pass `goal_id` to edit the active plan instead.']);
        }
        if (! isset($proposal->payload['schedule']['weeks']) || ! is_array($proposal->payload['schedule']['weeks'])) {
            return json_encode(['error' => 'Source proposal has no schedule.weeks to edit.']);
        }

        return [$proposal->payload, ProposalType::CreateSchedule];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function apply(array $payload, array $op): array
    {
        return match ($op['op'] ?? null) {
            'set_day' => $this->setDay($payload, $op),
            'remove_day' => $this->removeDay($payload, $op),
            'add_day' => $this->addDay($payload, $op),
            'shift_day' => $this->shiftDay($payload, $op),
            'set_goal' => $this->setGoal($payload, $op),
            default => throw new InvalidArgumentException("unknown op '".($op['op'] ?? 'null')."'"),
        };
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function setDay(array $payload, array $op): array
    {
        $week = $this->requireInt($op, 'week');
        $dow = $this->requireInt($op, 'day_of_week', min: 1, max: 7);
        $fields = $this->requireFields($op, 'set_day');

        $weekIndex = $this->findWeekIndex($payload, $week);
        $dayIndex = $this->findDayIndex($payload['schedule']['weeks'][$weekIndex]['days'] ?? [], $dow);
        if ($dayIndex === null) {
            throw new InvalidArgumentException(
                "week {$week} has no day on day_of_week {$dow}. "
                .$this->availableDaysHint($payload, $weekIndex)
                .' Use `set_day` on an existing day, or `add_day` to create a new one.'
            );
        }

        $validated = $this->validateDayFields($fields, strict: true);

        // If the op changes type or target_km but doesn't pass an explicit
        // title, null the existing title so the optimizer regenerates a
        // fresh "{km}km {TypeName}" label. Otherwise a stale "5km Tempo"
        // title survives on a day whose type was just flipped to `interval`.
        $shapeChanged = array_key_exists('type', $validated) || array_key_exists('target_km', $validated);
        if ($shapeChanged && ! array_key_exists('title', $validated)) {
            $validated['title'] = null;
        }

        $payload['schedule']['weeks'][$weekIndex]['days'][$dayIndex] = array_merge(
            $payload['schedule']['weeks'][$weekIndex]['days'][$dayIndex],
            $validated,
        );

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function removeDay(array $payload, array $op): array
    {
        $week = $this->requireInt($op, 'week');
        $dow = $this->requireInt($op, 'day_of_week', min: 1, max: 7);

        $weekIndex = $this->findWeekIndex($payload, $week);
        $dayIndex = $this->findDayIndex($payload['schedule']['weeks'][$weekIndex]['days'] ?? [], $dow);
        if ($dayIndex === null) {
            throw new InvalidArgumentException(
                "week {$week} has no day on day_of_week {$dow} to remove. "
                .$this->availableDaysHint($payload, $weekIndex)
            );
        }

        array_splice($payload['schedule']['weeks'][$weekIndex]['days'], $dayIndex, 1);
        $payload['schedule']['weeks'][$weekIndex]['days'] = array_values($payload['schedule']['weeks'][$weekIndex]['days']);

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function addDay(array $payload, array $op): array
    {
        $week = $this->requireInt($op, 'week');
        $dow = $this->requireInt($op, 'day_of_week', min: 1, max: 7);
        $fields = $this->requireFields($op, 'add_day');
        if (! isset($fields['type'], $fields['title'])) {
            throw new InvalidArgumentException("'fields.type' and 'fields.title' required for add_day");
        }

        $weekIndex = $this->findWeekIndex($payload, $week);
        $existing = $this->findDayIndex($payload['schedule']['weeks'][$weekIndex]['days'] ?? [], $dow);
        if ($existing !== null) {
            throw new InvalidArgumentException(
                "week {$week} already has a day on day_of_week {$dow}. Use `set_day` to modify it instead. "
                .$this->availableDaysHint($payload, $weekIndex)
            );
        }

        $newDay = array_merge(
            ['day_of_week' => $dow],
            $this->validateDayFields($fields, strict: true),
        );

        $payload['schedule']['weeks'][$weekIndex]['days'][] = $newDay;

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function shiftDay(array $payload, array $op): array
    {
        $week = $this->requireInt($op, 'week');
        $from = $this->requireInt($op, 'from_day_of_week', min: 1, max: 7);
        $to = $this->requireInt($op, 'to_day_of_week', min: 1, max: 7);
        if ($from === $to) {
            return $payload;
        }

        $weekIndex = $this->findWeekIndex($payload, $week);
        $days = $payload['schedule']['weeks'][$weekIndex]['days'] ?? [];
        $fromIndex = $this->findDayIndex($days, $from);
        if ($fromIndex === null) {
            throw new InvalidArgumentException(
                "week {$week} has no day on day_of_week {$from} to shift. "
                .$this->availableDaysHint($payload, $weekIndex)
            );
        }
        if ($this->findDayIndex($days, $to) !== null) {
            throw new InvalidArgumentException(
                "week {$week} already has a day on day_of_week {$to}. Shift that day first, or `remove_day` it, before moving another day to that slot."
            );
        }

        $payload['schedule']['weeks'][$weekIndex]['days'][$fromIndex]['day_of_week'] = $to;

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function setGoal(array $payload, array $op): array
    {
        $fields = $this->requireFields($op, 'set_goal');

        $allowed = ['goal_name', 'distance', 'goal_time_seconds', 'target_date', 'preferred_weekdays', 'additional_notes'];
        foreach ($fields as $key => $value) {
            if (! in_array($key, $allowed, true)) {
                throw new InvalidArgumentException("set_goal does not support field '{$key}'. Allowed: ".implode(', ', $allowed));
            }
            $payload[$key] = $this->validateGoalField($key, $value);
        }

        return $payload;
    }

    private function validateGoalField(string $key, mixed $value): mixed
    {
        return match ($key) {
            'goal_time_seconds' => $this->intValue($key, $value, min: 60),
            'distance' => in_array((string) $value, GoalDistance::values(), true)
                ? (string) $value
                : throw new InvalidArgumentException('distance must be one of: '.implode(', ', GoalDistance::values())),
            'target_date' => $this->dateValue($key, $value),
            'preferred_weekdays' => $this->weekdaysValue($value),
            'goal_name', 'additional_notes' => $value === null ? null : (string) $value,
            default => $value,
        };
    }

    /**
     * @param  array<string, mixed>  $fields
     * @return array<string, mixed>
     */
    private function validateDayFields(array $fields, bool $strict): array
    {
        $allowed = ['type', 'title', 'description', 'target_km', 'target_pace_seconds_per_km', 'target_heart_rate_zone', 'intervals'];
        $out = [];
        foreach ($fields as $key => $value) {
            if (! in_array($key, $allowed, true)) {
                if ($strict) {
                    throw new InvalidArgumentException("unknown day field '{$key}'. Allowed: ".implode(', ', $allowed));
                }

                continue;
            }

            $out[$key] = match ($key) {
                'type' => in_array((string) $value, TrainingType::activeValues(), true)
                    ? (string) $value
                    : throw new InvalidArgumentException('type must be one of: '.implode(', ', TrainingType::activeValues())),
                'title', 'description' => $value === null ? null : (string) $value,
                'target_km' => $value === null ? null : $this->positiveNumber('target_km', $value),
                'target_pace_seconds_per_km' => $value === null ? null : $this->intValue('target_pace_seconds_per_km', $value, min: 60, max: 1800),
                'target_heart_rate_zone' => $value === null ? null : $this->intValue('target_heart_rate_zone', $value, min: 1, max: 5),
                'intervals' => $value,
                default => $value,
            };
        }

        return $out;
    }

    private function positiveNumber(string $key, mixed $value): float
    {
        if (! is_numeric($value) || (float) $value <= 0) {
            throw new InvalidArgumentException("'{$key}' must be a positive number");
        }

        return (float) $value;
    }

    private function intValue(string $key, mixed $value, ?int $min = null, ?int $max = null): int
    {
        if (! is_numeric($value)) {
            throw new InvalidArgumentException("'{$key}' must be an integer");
        }
        $int = (int) $value;
        if ($min !== null && $int < $min) {
            throw new InvalidArgumentException("'{$key}' must be >= {$min}");
        }
        if ($max !== null && $int > $max) {
            throw new InvalidArgumentException("'{$key}' must be <= {$max}");
        }

        return $int;
    }

    private function dateValue(string $key, mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $s = (string) $value;
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $s)) {
            throw new InvalidArgumentException("'{$key}' must be a YYYY-MM-DD date");
        }

        return $s;
    }

    /**
     * @return array<int, int>|null
     */
    private function weekdaysValue(mixed $value): ?array
    {
        if ($value === null) {
            return null;
        }
        if (! is_array($value)) {
            throw new InvalidArgumentException('preferred_weekdays must be an array of integers 1-7');
        }
        $out = [];
        foreach ($value as $v) {
            if (! is_numeric($v)) {
                throw new InvalidArgumentException('preferred_weekdays entries must be integers 1-7');
            }
            $i = (int) $v;
            if ($i < 1 || $i > 7) {
                throw new InvalidArgumentException('preferred_weekdays entries must be between 1 and 7');
            }
            $out[] = $i;
        }
        $out = array_values(array_unique($out));
        sort($out);

        return $out === [] ? null : $out;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function findWeekIndex(array $payload, int $weekNumber): int
    {
        foreach ($payload['schedule']['weeks'] ?? [] as $i => $week) {
            if (($week['week_number'] ?? null) === $weekNumber) {
                return $i;
            }
        }
        $available = [];
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            if (isset($week['week_number'])) {
                $available[] = (int) $week['week_number'];
            }
        }
        sort($available);
        $availableCsv = $available === [] ? '(plan has no weeks)' : 'Available week_numbers: ['.implode(', ', $available).'].';
        throw new InvalidArgumentException("no week with week_number {$weekNumber}. {$availableCsv}");
    }

    /**
     * Build a short hint listing which day_of_week values actually exist
     * in the target week, so the agent can retry with a valid op on its
     * very next turn instead of guessing.
     *
     * @param  array<string, mixed>  $payload
     */
    private function availableDaysHint(array $payload, int $weekIndex): string
    {
        $days = $payload['schedule']['weeks'][$weekIndex]['days'] ?? [];
        $dows = [];
        foreach ($days as $day) {
            if (isset($day['day_of_week'])) {
                $dows[] = (int) $day['day_of_week'];
            }
        }
        sort($dows);

        return $dows === []
            ? 'That week currently has no scheduled days.'
            : 'That week has days on day_of_week: ['.implode(', ', $dows).'].';
    }

    /**
     * @param  array<int, array<string, mixed>>  $days
     */
    private function findDayIndex(array $days, int $dayOfWeek): ?int
    {
        foreach ($days as $i => $day) {
            if (($day['day_of_week'] ?? null) === $dayOfWeek) {
                return $i;
            }
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $op
     */
    private function requireInt(array $op, string $key, ?int $min = null, ?int $max = null): int
    {
        if (! array_key_exists($key, $op) || ! is_numeric($op[$key])) {
            throw new InvalidArgumentException("'{$key}' is required (integer)");
        }
        $value = (int) $op[$key];
        if ($min !== null && $value < $min) {
            throw new InvalidArgumentException("'{$key}' must be >= {$min}");
        }
        if ($max !== null && $value > $max) {
            throw new InvalidArgumentException("'{$key}' must be <= {$max}");
        }

        return $value;
    }

    /**
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function requireFields(array $op, string $opName): array
    {
        $fields = $op['fields'] ?? null;
        if (! is_array($fields) || count($fields) === 0) {
            throw new InvalidArgumentException("'fields' (non-empty object) required for {$opName}");
        }

        return $fields;
    }
}
