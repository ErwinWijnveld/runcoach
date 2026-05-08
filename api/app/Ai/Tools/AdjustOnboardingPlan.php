<?php

namespace App\Ai\Tools;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use App\Support\PlanPayload;
use Carbon\Carbon;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Optional second-pass tool for the OnboardingAgent. After the
 * deterministic builder produces the draft proposal, the agent can
 * call THIS tool to make targeted adjustments based on the runner's
 * additional_notes (or context from get_recent_runs).
 *
 * Operations are JSON-encoded into the `operations` field — same
 * pragmatic approach `CreateSchedule` uses for nested JSON. Each op
 * is validated against guard rails server-side; bad ops are skipped
 * (with a reason in the response) rather than aborting the whole call.
 *
 * Guard rails:
 *  - Race day (date == target_date) is untouchable. Any op against it
 *    is rejected.
 *  - `add` ops only succeed when `day_of_week` is in the runner's
 *    `preferred_weekdays` (or no preference is set).
 *  - Pace overrides are clamped to ±15 sec/km on tempo days, ±10 sec/km
 *    on per-segment interval work paces, relative to the builder's
 *    value. Easy/long-run paces are not overridable here (they're
 *    structurally tied to `snapshot.easyPaceSecondsPerKm`).
 *  - Distance overrides are clamped to [4 km, builder_value × 1.5].
 *
 * After ops apply, `PlanOptimizerService::optimize` runs again so
 * weekly totals / race-day enforcement stay coherent. The updated
 * payload supersedes the previous proposal via
 * `ProposalService::persistPending`.
 */
class AdjustOnboardingPlan implements Tool
{
    public const TEMPO_PACE_TOLERANCE_SECONDS = 15;

    public const INTERVAL_WORK_PACE_TOLERANCE_SECONDS = 10;

    public const KM_MAX_MULTIPLIER = 1.5;

    public const KM_MIN = 4.0;

    public function __construct(
        private User $user,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string
    {
        $types = TrainingType::activeValuesAsPipe();

        return <<<DESC
        Apply small targeted edits to the runner's draft training plan based on their additional_notes (or context from get_recent_runs). Operates on the latest pending proposal — call this AFTER build_onboarding_plan, only when the notes warrant it.

        WHEN TO CALL THIS:
        - Runner notes mention specific session preferences ("more intervals", "I prefer hill workouts", "no tempos please").
        - Runner notes mention a constraint ("coming back from injury, easier first 4 weeks").
        - Runner notes name a free weekday that should host an extra session ("I can also run Wednesdays").

        WHEN NOT TO CALL THIS:
        - Notes are empty / generic ("looking forward to it" / "thanks").
        - Notes don't translate to a structural change (e.g. "I love running" — nothing to do).

        Operations is a JSON string with shape:
        {"operations":[
          {"action":"replace","week":3,"day_of_week":2,"type":"{$types}","target_km":7.5,"description":"..."},
          {"action":"add","week":4,"day_of_week":3,"type":"interval","target_km":6,"description":"..."},
          {"action":"remove","week":5,"day_of_week":7},
          {"action":"adjust","week":2,"day_of_week":4,"target_km":8.0}
        ]}

        Action semantics:
        - replace — overwrite the day at (week, day_of_week). Day must exist.
        - add — add a new day at (week, day_of_week). Day must not already exist; day_of_week must be in preferred_weekdays.
        - remove — drop the day. Race day (target_date) cannot be removed.
        - adjust — partial update of an existing day; only the provided fields change.

        Pace tolerances (server clamps; out-of-range values are silently capped):
        - target_pace_seconds_per_km: ±15s for tempo, ±10s for interval `work` segments.
        - Easy / long-run paces cannot be overridden — they track the runner's snapshot.

        Distance bounds: 4 km min, 1.5× the builder's value max.

        Use as many operations as needed (no hard cap) but don't rewrite the whole plan — the deterministic structure (volume curve, taper, race day) is the right starting point. The reply should NOT mention this tool or operations to the runner; mention the change in human terms ("I added an interval day on Wednesday").
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'reason' => $schema->string()
                ->required()
                ->description('Brief, runner-readable explanation of why these changes ("Runner asked for more interval work").'),
            'operations' => $schema->string()
                ->required()
                ->description('JSON-encoded array of operations. See tool description for shape.'),
        ];
    }

    public function handle(Request $request): string
    {
        $proposal = $this->latestPendingProposal();
        if ($proposal === null) {
            return json_encode([
                'error' => 'No pending proposal found. Call build_onboarding_plan first.',
            ]);
        }

        $payload = $proposal->payload;
        $operations = $this->decodeOperations($request['operations'] ?? null);
        if ($operations === null) {
            return json_encode([
                'error' => 'Could not parse operations JSON.',
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
                    'day_of_week' => $op['day_of_week'] ?? null,
                    'note' => $result['note'] ?? null,
                ];
            } else {
                $rejected[] = [
                    'index' => $i,
                    'reason' => $result['reason'],
                ];
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

        $payload = $this->optimizer->optimize($payload, $this->user);

        $newProposal = $this->proposals->persistPending(
            $this->user,
            ProposalType::CreateSchedule,
            $payload,
        );

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => ProposalType::CreateSchedule->value,
            'proposal_id' => $newProposal->id,
            'plan_structure' => PlanPayload::weekStructure($payload),
            'applied' => $applied,
            'rejected' => $rejected,
            'reason' => $request['reason'] ?? null,
        ]);
    }

    private function latestPendingProposal(): ?CoachProposal
    {
        return CoachProposal::where('user_id', $this->user->id)
            ->where('status', ProposalStatus::Pending)
            ->latest('id')
            ->first();
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

        // Accept either {operations:[...]} or [...] directly.
        $list = $decoded['operations'] ?? $decoded;
        if (! is_array($list)) {
            return null;
        }

        return array_values(array_filter($list, 'is_array'));
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, note?: string, reason?: string}
     */
    private function applyOperation(array $payload, array $op): array
    {
        $action = $op['action'] ?? null;
        $week = (int) ($op['week'] ?? 0);
        $dow = (int) ($op['day_of_week'] ?? 0);

        if (! in_array($action, ['replace', 'add', 'remove', 'adjust'], true)) {
            return ['ok' => false, 'reason' => "unknown action '{$action}'"];
        }
        if ($week < 1 || $dow < 1 || $dow > 7) {
            return ['ok' => false, 'reason' => 'invalid (week, day_of_week)'];
        }

        if ($this->isRaceDay($payload, $week, $dow)) {
            return ['ok' => false, 'reason' => 'cannot modify race day'];
        }

        return match ($action) {
            'replace' => $this->doReplace($payload, $week, $dow, $op),
            'add' => $this->doAdd($payload, $week, $dow, $op),
            'remove' => $this->doRemove($payload, $week, $dow),
            'adjust' => $this->doAdjust($payload, $week, $dow, $op),
            default => ['ok' => false, 'reason' => "unknown action '{$action}'"],
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
     * @return array{ok: bool, payload?: array<string, mixed>, note?: string, reason?: string}
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
     * @return array{ok: bool, payload?: array<string, mixed>, note?: string, reason?: string}
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
        $next = $this->mergeDayFields($skeleton, $op);
        $next['day_of_week'] = $dow;
        $payload['schedule']['weeks'][$wi]['days'][] = $next;

        // Keep the week's days ordered by day_of_week for predictability.
        usort(
            $payload['schedule']['weeks'][$wi]['days'],
            fn ($a, $b) => ($a['day_of_week'] ?? 0) <=> ($b['day_of_week'] ?? 0),
        );

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array{ok: bool, payload?: array<string, mixed>, note?: string, reason?: string}
     */
    private function doRemove(array $payload, int $week, int $dow): array
    {
        [$wi, $di] = $this->locate($payload, $week, $dow);
        if ($wi === null || $di === null) {
            return ['ok' => false, 'reason' => "week {$week} day {$dow} does not exist"];
        }

        array_splice($payload['schedule']['weeks'][$wi]['days'], $di, 1);
        $payload['schedule']['weeks'][$wi]['days'] = array_values(
            $payload['schedule']['weeks'][$wi]['days']
        );

        return ['ok' => true, 'payload' => $payload];
    }

    /**
     * @param  array<string, mixed>  $payload
     * @param  array<string, mixed>  $op
     * @return array{ok: bool, payload?: array<string, mixed>, note?: string, reason?: string}
     */
    private function doAdjust(array $payload, int $week, int $dow, array $op): array
    {
        return $this->doReplace($payload, $week, $dow, $op);
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array{0: int|null, 1: int|null} [week_index, day_index]
     */
    private function locate(array $payload, int $week, int $dow): array
    {
        $weeks = $payload['schedule']['weeks'] ?? [];
        foreach ($weeks as $wi => $w) {
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
    private function mergeDayFields(array $existing, array $op): array
    {
        $next = $existing;

        if (isset($op['type'])) {
            $type = TrainingType::tryFrom((string) $op['type']);
            if ($type !== null) {
                $next['type'] = $type->value;
                if ($type !== TrainingType::Interval) {
                    // Switching away from interval: clear segments so the
                    // optimizer doesn't treat it as an interval session.
                    $next['intervals'] = null;
                }
            }
        }

        if (array_key_exists('target_km', $op) && is_numeric($op['target_km'])) {
            $existingKm = (float) ($existing['target_km'] ?? 0);
            $maxKm = $existingKm > 0 ? $existingKm * self::KM_MAX_MULTIPLIER : 30.0;
            $km = (float) $op['target_km'];
            $next['target_km'] = max(self::KM_MIN, min($maxKm, $km));
        }

        if (array_key_exists('description', $op) && is_string($op['description'])) {
            $next['description'] = trim($op['description']);
        }

        if (array_key_exists('target_pace_seconds_per_km', $op) && is_numeric($op['target_pace_seconds_per_km'])) {
            $type = $next['type'] ?? TrainingType::Easy->value;
            // Easy / long-run paces stay tied to the snapshot — silently ignore.
            if ($type === TrainingType::Tempo->value || $type === TrainingType::Threshold->value) {
                $existingPace = (int) ($existing['target_pace_seconds_per_km'] ?? 0);
                if ($existingPace > 0) {
                    $proposed = (int) $op['target_pace_seconds_per_km'];
                    $next['target_pace_seconds_per_km'] = max(
                        $existingPace - self::TEMPO_PACE_TOLERANCE_SECONDS,
                        min($existingPace + self::TEMPO_PACE_TOLERANCE_SECONDS, $proposed),
                    );
                }
            }
        }

        return $next;
    }
}
