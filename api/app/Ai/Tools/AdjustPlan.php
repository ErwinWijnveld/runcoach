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
use Carbon\Carbon;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Unified plan-edit tool used by BOTH OnboardingAgent (during loading
 * screen) AND RunCoachAgent (post-acceptance chat). Supersedes the old
 * `EditSchedule` + `AdjustOnboardingPlan` pair.
 *
 * Auto-targets in this order:
 *   1. Latest pending proposal (CreateSchedule type).
 *   2. Runner's active Goal (in-place edit).
 *   3. Most recent any-status proposal (covers reject-then-adjust flow).
 *
 * Operations (JSON-encoded array, flat shape):
 *   • {"action":"replace","week":3,"day_of_week":2,"type":"easy","target_km":5,"description":"..."}
 *   • {"action":"add","week":3,"day_of_week":4,"type":"interval","target_km":6,"description":"..."}
 *   • {"action":"remove","week":3,"day_of_week":7}
 *   • {"action":"adjust","week":3,"day_of_week":2,"target_km":7}   // partial update
 *   • {"action":"shift","week":3,"from_day_of_week":2,"to_day_of_week":4}
 *   • {"action":"set_goal","goal_name":"...","distance":"5k","goal_time_seconds":1500,"target_date":"...","preferred_weekdays":[2,4,6],"additional_notes":"..."}
 *
 * Server-side guard rails (silent clamps):
 *   • Pace overrides on tempo/threshold days clamped to ±15 sec/km vs the
 *     existing pace. Easy/long-run paces are not overridable (they track
 *     the runner's snapshot, the optimizer fills them).
 *   • Distance clamped to [4 km, 1.5× the existing day's km] (or 30 km
 *     ceiling when adding from scratch).
 *   • Race day (date == target_date) is untouchable. Any op against it
 *     is rejected with a reason.
 *   • `add` respects `preferred_weekdays` when present.
 *
 * After ops apply, the optimizer runs (alignRaceDay=false on edits, since
 * the user reasoned about target_date already). For active-goal edits we
 * attach a `diff` array so the proposal card renders "PLAN REVISION (N
 * changes)". Onboarding edits (still-pending proposal) skip the diff so
 * the runner doesn't see a revision card before they've accepted anything.
 *
 * No verify loop. Sonnet emits ops, server clamps + optimizes, the
 * deterministic builder handles structural correctness elsewhere.
 */
class AdjustPlan implements Tool
{
    public const TEMPO_PACE_TOLERANCE_SECONDS = 15;

    public const INTERVAL_WORK_PACE_TOLERANCE_SECONDS = 10;

    public const KM_MAX_MULTIPLIER = 1.5;

    public const KM_MIN = 4.0;

    /** Absolute distance ceiling for added (no-prior-km) days. */
    public const KM_ADD_CEILING = 30.0;

    public function __construct(
        private User $user,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string
    {
        $types = TrainingType::activeValuesAsPipe();
        $distanceCsv = '"'.implode('", "', GoalDistance::values()).'"';

        return <<<DESC
        Apply targeted edits to the runner's training plan — works on either the latest pending proposal OR the active plan (auto-detects). Use for ANY tweak: changing a day's type / pace / km, dropping a day, adding a session, shifting a day to another weekday, or updating goal metadata. MUCH cheaper and faster than rebuilding via build_plan; use this for everything except a fundamental restructure.

        WHEN TO CALL THIS:
        - Specific changes: "make Tuesday a tempo", "add an interval on Wed", "drop the Friday easy", "shift the long run to Saturday".
        - Pace / distance tweaks: "make my tempos 10 sec/km faster", "shorten the long runs".
        - Goal metadata: "race date moved to ...", "I want to aim for 21:00 instead", "I can also run on Wednesdays now".
        - Injury accommodations during onboarding: "replace tempos in weeks 1-6 with easy".
        - Vague rejection during onboarding: pair with `offer_choices` first to clarify.

        WHEN NOT TO CALL THIS:
        - Empty / generic notes ("looking forward to it") → no edit needed.
        - Fundamental restructure (different goal_type, completely new plan because race got cancelled, switching from race to PR-attempt) → use `build_plan` instead.

        Operations is a JSON string with shape `{"operations":[ ... ]}`. Each op is one of:

        - {"action":"replace","week":3,"day_of_week":2,"type":"{$types}","target_km":7.5,"description":"..."}
          Overwrite an existing day. Day must exist on (week, day_of_week).

        - {"action":"add","week":4,"day_of_week":3,"type":"interval","target_km":6,"description":"..."}
          Add a new day. day_of_week must be in preferred_weekdays. Fails if a day already exists on that slot.

        - {"action":"remove","week":5,"day_of_week":7}
          Drop the day. Race day (date == target_date) cannot be removed.

        - {"action":"adjust","week":2,"day_of_week":4,"target_km":8.0,"description":"..."}
          Partial update — only the provided fields change.

        - {"action":"shift","week":3,"from_day_of_week":2,"to_day_of_week":4}
          Move a day to a different weekday inside the same week. Target slot must be free.

        - {"action":"set_goal","goal_name":"...","distance":"5k","goal_time_seconds":1500,"target_date":"YYYY-MM-DD","preferred_weekdays":[2,4,6],"additional_notes":"..."}
          Update goal metadata. `distance` must be a GoalDistance enum value (one of: {$distanceCsv}). `goal_type` and `coach_style` are NOT editable here — use `build_plan` for those.

        Server clamps (silent — out-of-range values get capped):
        - target_pace_seconds_per_km: ±15s for tempo/threshold, ±10s for interval `work` segments. Easy/long-run paces cannot be overridden (server backfills from runner's snapshot).
        - target_km: [4 km min, 1.5× the existing value max], or [4, 30] for `add`.

        Use as many operations as the runner needs (no hard cap), but don't rewrite the whole plan — for that, call `build_plan`. The reply should NOT mention this tool, "operations", or internal mechanics; describe changes in human terms ("I added an interval on Wednesday").
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'reason' => $schema->string()
                ->required()
                ->description('Brief, runner-readable explanation ("Runner asked for an extra interval day").'),
            'operations' => $schema->string()
                ->required()
                ->description('JSON-encoded `{"operations":[...]}`. See tool description for op shapes.'),
        ];
    }

    public function handle(Request $request): string
    {
        $resolved = $this->resolveTarget();
        if (is_string($resolved)) {
            return $resolved;
        }
        [$payload, $proposalType] = $resolved;

        $operations = $this->decodeOperations($request['operations'] ?? null);
        if ($operations === null) {
            return json_encode([
                'error' => 'Could not parse operations JSON. Expect `{"operations":[...]}`.',
            ]);
        }

        $applied = [];
        $rejected = [];

        foreach ($operations as $i => $op) {
            $result = $this->applyOperation($payload, $op);
            if ($result['ok']) {
                $payload = $result['payload'];
                $applied[] = [
                    'index' => $i,
                    'action' => $op['action'] ?? null,
                    'week' => $op['week'] ?? null,
                    'day_of_week' => $op['day_of_week'] ?? $op['from_day_of_week'] ?? null,
                ];
            } else {
                $rejected[] = ['index' => $i, 'reason' => $result['reason']];
            }
        }

        if ($applied === []) {
            return json_encode([
                'requires_approval' => false,
                'applied' => [],
                'rejected' => $rejected,
                'note' => 'No operations applied; original proposal stands.',
            ]);
        }

        // Run optimizer with alignRaceDay=false (user already reasoned
        // about target_date) and lenient preferred_weekdays — except
        // when this edit explicitly updated `preferred_weekdays`, in
        // which case strict mode drops days that don't match the new
        // pref.
        $strictPrefs = $this->editTouchedPreferredWeekdays($operations);
        $payload = $this->optimizer->optimize(
            $payload,
            $this->user,
            alignRaceDay: false,
            strictPreferredWeekdays: $strictPrefs,
        );

        // Attach `diff` only for active-goal edits — that's where the
        // "PLAN REVISION (N changes)" UI is meaningful. Onboarding edits
        // (still-pending proposal) get no diff: the runner hasn't seen
        // any prior version of the plan.
        if ($proposalType === ProposalType::EditActivePlan) {
            $payload['diff'] = array_values($operations);
        } else {
            unset($payload['diff']);
        }

        $newProposal = $this->proposals->persistPending($this->user, $proposalType, $payload);

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => $proposalType->value,
            'proposal_id' => $newProposal->id,
            'plan_structure' => PlanPayload::weekStructure($payload),
            'applied' => $applied,
            'rejected' => $rejected,
            'reason' => $request['reason'] ?? null,
        ]);
    }

    /**
     * @return array{0: array<string, mixed>, 1: ProposalType}|string
     */
    private function resolveTarget(): array|string
    {
        // 1. Latest pending CreateSchedule proposal (onboarding flow,
        //    or post-rejection chat tweak).
        $pending = CoachProposal::where('user_id', $this->user->id)
            ->where('status', ProposalStatus::Pending)
            ->where('type', ProposalType::CreateSchedule)
            ->latest('id')
            ->first();
        if ($pending !== null) {
            return [$pending->payload, ProposalType::CreateSchedule];
        }

        // 2. Active Goal — chat edits to a plan the runner already accepted.
        $activeGoal = $this->user->goals()
            ->where('status', GoalStatus::Active)
            ->latest('id')
            ->first();
        if ($activeGoal !== null) {
            return [PlanPayload::fromGoal($activeGoal), ProposalType::EditActivePlan];
        }

        // 3. Fallback: latest any-status CreateSchedule proposal (covers
        //    reject-then-adjust flow during onboarding when the runner
        //    rejected the first plan and is now asking for changes).
        $latest = CoachProposal::where('user_id', $this->user->id)
            ->where('type', ProposalType::CreateSchedule)
            ->latest('id')
            ->first();
        if ($latest !== null) {
            return [$latest->payload, ProposalType::CreateSchedule];
        }

        return json_encode([
            'error' => 'No proposal or active plan found to edit. Use build_plan to create a new one.',
        ]);
    }

    /**
     * @return list<array<string, mixed>>|null
     */
    private function decodeOperations(?string $raw): ?array
    {
        if (! is_string($raw) || trim($raw) === '') {
            return null;
        }
        $decoded = json_decode($raw, true);
        if (! is_array($decoded)) {
            return null;
        }
        $list = $decoded['operations'] ?? $decoded;
        if (! is_array($list)) {
            return null;
        }

        return array_values(array_filter($list, 'is_array'));
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function applyOperation(array $payload, array $op): array
    {
        $action = $op['action'] ?? null;

        if ($action === 'set_goal') {
            return $this->doSetGoal($payload, $op);
        }
        if ($action === 'shift') {
            return $this->doShift($payload, $op);
        }
        if (! in_array($action, ['replace', 'add', 'remove', 'adjust'], true)) {
            return ['ok' => false, 'reason' => "unknown action '{$action}'"];
        }

        $week = (int) ($op['week'] ?? 0);
        $dow = (int) ($op['day_of_week'] ?? 0);
        if ($week < 1 || $dow < 1 || $dow > 7) {
            return ['ok' => false, 'reason' => 'invalid (week, day_of_week)'];
        }

        if ($this->isRaceDay($payload, $week, $dow)) {
            return ['ok' => false, 'reason' => 'cannot modify race day'];
        }

        return match ($action) {
            'replace', 'adjust' => $this->doReplace($payload, $week, $dow, $op),
            'add' => $this->doAdd($payload, $week, $dow, $op),
            'remove' => $this->doRemove($payload, $week, $dow),
        };
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function isRaceDay(array $payload, int $week, int $dow): bool
    {
        $stated = $payload['target_date'] ?? null;
        if (! is_string($stated) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated)) {
            return false;
        }
        $target = Carbon::parse($stated)->startOfDay();
        $weekStart = Carbon::now()->startOfWeek()->addWeeks($week - 1);
        $date = $weekStart->copy()->addDays($dow - 1);

        return $date->equalTo($target);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function doReplace(array $payload, int $week, int $dow, array $op): array
    {
        [$wi, $di] = $this->locate($payload, $week, $dow);
        if ($wi === null || $di === null) {
            return ['ok' => false, 'reason' => "week {$week} day {$dow} does not exist (use add)"];
        }
        $existing = $payload['schedule']['weeks'][$wi]['days'][$di];
        $next = $this->mergeDayFields($existing, $op);
        $payload['schedule']['weeks'][$wi]['days'][$di] = $next;

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function doAdd(array $payload, int $week, int $dow, array $op): array
    {
        $preferred = $payload['preferred_weekdays'] ?? null;
        if (is_array($preferred) && $preferred !== [] && ! in_array($dow, array_map('intval', $preferred), true)) {
            return ['ok' => false, 'reason' => "day_of_week {$dow} not in preferred_weekdays"];
        }
        [$wi, $di] = $this->locate($payload, $week, $dow);
        if ($di !== null) {
            return ['ok' => false, 'reason' => "week {$week} day {$dow} already exists (use replace or adjust)"];
        }
        if ($wi === null) {
            return ['ok' => false, 'reason' => "week {$week} does not exist"];
        }

        $skeleton = [
            'day_of_week' => $dow,
            'type' => TrainingType::Easy->value,
            'target_km' => self::KM_MIN,
            'description' => 'Added per runner request.',
            'target_pace_seconds_per_km' => null,
        ];
        $next = $this->mergeDayFields($skeleton, $op, isAdd: true);
        $next['day_of_week'] = $dow;
        $payload['schedule']['weeks'][$wi]['days'][] = $next;

        usort(
            $payload['schedule']['weeks'][$wi]['days'],
            fn ($a, $b) => ($a['day_of_week'] ?? 0) <=> ($b['day_of_week'] ?? 0),
        );

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function doRemove(array $payload, int $week, int $dow): array
    {
        [$wi, $di] = $this->locate($payload, $week, $dow);
        if ($wi === null || $di === null) {
            return ['ok' => false, 'reason' => "week {$week} day {$dow} does not exist"];
        }
        array_splice($payload['schedule']['weeks'][$wi]['days'], $di, 1);
        $payload['schedule']['weeks'][$wi]['days'] = array_values($payload['schedule']['weeks'][$wi]['days']);

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * Move a day to a different weekday in the same week. Target slot
     * must be empty.
     *
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function doShift(array $payload, array $op): array
    {
        $week = (int) ($op['week'] ?? 0);
        $from = (int) ($op['from_day_of_week'] ?? 0);
        $to = (int) ($op['to_day_of_week'] ?? 0);
        if ($week < 1 || $from < 1 || $from > 7 || $to < 1 || $to > 7) {
            return ['ok' => false, 'reason' => 'invalid (week, from_day_of_week, to_day_of_week)'];
        }
        if ($from === $to) {
            return ['ok' => true, 'payload' => $payload];
        }
        if ($this->isRaceDay($payload, $week, $from)) {
            return ['ok' => false, 'reason' => 'cannot shift race day'];
        }

        [$wi, $fromIdx] = $this->locate($payload, $week, $from);
        if ($wi === null || $fromIdx === null) {
            return ['ok' => false, 'reason' => "week {$week} has no day on day_of_week {$from} to shift"];
        }
        if ($this->locate($payload, $week, $to)[1] !== null) {
            return ['ok' => false, 'reason' => "week {$week} already has a day on day_of_week {$to}; remove or shift it first"];
        }

        $payload['schedule']['weeks'][$wi]['days'][$fromIdx]['day_of_week'] = $to;
        usort(
            $payload['schedule']['weeks'][$wi]['days'],
            fn ($a, $b) => ($a['day_of_week'] ?? 0) <=> ($b['day_of_week'] ?? 0),
        );

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * Update goal metadata (top-level payload fields).
     *
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, reason?: string}
     */
    private function doSetGoal(array $payload, array $op): array
    {
        $allowed = ['goal_name', 'distance', 'goal_time_seconds', 'target_date', 'preferred_weekdays', 'additional_notes'];

        $touched = false;
        foreach ($allowed as $key) {
            if (! array_key_exists($key, $op)) {
                continue;
            }
            $touched = true;
            $value = $op[$key];

            $valid = match ($key) {
                'goal_time_seconds' => $this->validateGoalTime($value),
                'distance' => $this->validateDistance($value),
                'target_date' => $this->validateTargetDate($value),
                'preferred_weekdays' => $this->validatePreferredWeekdays($value),
                'goal_name', 'additional_notes' => $value === null ? null : (string) $value,
                default => $value,
            };
            if ($valid === false) {
                return ['ok' => false, 'reason' => "invalid value for '{$key}'"];
            }
            $payload[$key] = $valid;
        }

        if (! $touched) {
            return ['ok' => false, 'reason' => 'set_goal requires at least one allowed field'];
        }

        return ['ok' => true, 'payload' => $payload];
    }

    private function validateGoalTime(mixed $value): int|null|false
    {
        if ($value === null) {
            return null;
        }
        if (! is_numeric($value)) {
            return false;
        }
        $int = (int) $value;

        return $int >= 60 && $int <= 86400 ? $int : false;
    }

    private function validateDistance(mixed $value): string|null|false
    {
        if ($value === null) {
            return null;
        }
        $str = (string) $value;

        return in_array($str, GoalDistance::values(), true) ? $str : false;
    }

    private function validateTargetDate(mixed $value): string|null|false
    {
        if ($value === null) {
            return null;
        }
        $s = (string) $value;

        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $s) ? $s : false;
    }

    /**
     * @return array<int, int>|null|false
     */
    private function validatePreferredWeekdays(mixed $value): array|null|false
    {
        if ($value === null) {
            return null;
        }
        if (! is_array($value)) {
            return false;
        }
        $out = [];
        foreach ($value as $v) {
            if (! is_numeric($v)) {
                return false;
            }
            $i = (int) $v;
            if ($i < 1 || $i > 7) {
                return false;
            }
            if (! in_array($i, $out, true)) {
                $out[] = $i;
            }
        }
        sort($out);

        return $out === [] ? null : $out;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array{0: int|null, 1: int|null}
     */
    private function locate(array $payload, int $week, int $dow): array
    {
        foreach (($payload['schedule']['weeks'] ?? []) as $wi => $w) {
            if ((int) ($w['week_number'] ?? 0) !== $week) {
                continue;
            }
            foreach (($w['days'] ?? []) as $di => $d) {
                if ((int) ($d['day_of_week'] ?? 0) === $dow) {
                    return [$wi, $di];
                }
            }

            return [$wi, null];
        }

        return [null, null];
    }

    /**
     * Merge AI-supplied fields into a day, applying guard-rail clamps.
     *
     * @param  array<string, mixed>  $existing
     * @param  array<string, mixed>  $op
     * @return array<string, mixed>
     */
    private function mergeDayFields(array $existing, array $op, bool $isAdd = false): array
    {
        $next = $existing;

        if (isset($op['type'])) {
            $type = TrainingType::tryFrom((string) $op['type']);
            if ($type !== null) {
                $previousType = $existing['type'] ?? null;
                $next['type'] = $type->value;
                if ($type !== TrainingType::Interval) {
                    $next['intervals'] = null;
                }
                // Type changed → wipe stale type-derived fields so the
                // optimizer regenerates them. Without this, a tempo→interval
                // replace keeps the old "Tempo" title + tempo pace and the
                // resulting card / details sheet looks identical to the
                // original. Explicit title/pace in the same op (handled
                // below) still wins.
                if ($previousType !== null && $previousType !== $type->value) {
                    $next['title'] = null;
                    $next['target_pace_seconds_per_km'] = null;
                    if ($type === TrainingType::Interval) {
                        $next['intervals'] = null;
                    }
                }
            }
        }

        if (array_key_exists('target_km', $op) && is_numeric($op['target_km'])) {
            $existingKm = (float) ($existing['target_km'] ?? 0);
            $maxKm = $existingKm > 0
                ? $existingKm * self::KM_MAX_MULTIPLIER
                : ($isAdd ? self::KM_ADD_CEILING : 30.0);
            $km = (float) $op['target_km'];
            $next['target_km'] = max(self::KM_MIN, min($maxKm, $km));
        }

        if (array_key_exists('description', $op) && is_string($op['description'])) {
            $next['description'] = trim($op['description']);
        }
        if (array_key_exists('title', $op)) {
            $next['title'] = is_string($op['title']) ? trim($op['title']) : null;
        }

        if (array_key_exists('target_pace_seconds_per_km', $op) && is_numeric($op['target_pace_seconds_per_km'])) {
            $type = $next['type'] ?? TrainingType::Easy->value;
            // Easy / long-run paces are not overridable here (they track the snapshot).
            if (in_array($type, [TrainingType::Tempo->value, TrainingType::Threshold->value], true)) {
                $existingPace = (int) ($existing['target_pace_seconds_per_km'] ?? 0);
                $proposed = (int) $op['target_pace_seconds_per_km'];
                if ($existingPace > 0) {
                    $next['target_pace_seconds_per_km'] = max(
                        $existingPace - self::TEMPO_PACE_TOLERANCE_SECONDS,
                        min($existingPace + self::TEMPO_PACE_TOLERANCE_SECONDS, $proposed),
                    );
                } else {
                    // No prior pace — accept the proposed value within sanity bounds.
                    $next['target_pace_seconds_per_km'] = max(150, min(720, $proposed));
                }
            }
        }

        if (array_key_exists('target_heart_rate_zone', $op) && is_numeric($op['target_heart_rate_zone'])) {
            $z = (int) $op['target_heart_rate_zone'];
            if ($z >= 1 && $z <= 5) {
                $next['target_heart_rate_zone'] = $z;
            }
        }

        // Intervals override (workout-level edit). Only applied when the
        // resulting day type is `interval` — the type-clearing logic above
        // already nulls the array when switching to a non-interval type.
        if (array_key_exists('intervals', $op)
            && ($next['type'] ?? null) === TrainingType::Interval->value) {
            $next['intervals'] = is_array($op['intervals']) ? $op['intervals'] : null;
        }

        return $next;
    }

    /**
     * Did any op explicitly update `preferred_weekdays`? Drives whether
     * the optimizer runs in strict-mode (drop days that don't match the
     * new pref) or lenient mode (auto-extend the pref to cover whatever
     * the agent added).
     *
     * @param  list<array<string, mixed>>  $operations
     */
    private function editTouchedPreferredWeekdays(array $operations): bool
    {
        foreach ($operations as $op) {
            if (($op['action'] ?? null) === 'set_goal' && array_key_exists('preferred_weekdays', $op)) {
                return true;
            }
        }

        return false;
    }
}
