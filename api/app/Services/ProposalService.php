<?php

namespace App\Services;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ProposalService
{
    public function __construct(private GoalService $goals) {}

    /**
     * Detect proposals from the SDK's stored tool results after an agent prompt.
     * The SDK stores tool_calls and tool_results in agent_conversation_messages.
     */
    public function detectProposalFromConversation(User $user, string $conversationId): ?CoachProposal
    {
        // Get the latest assistant message from this conversation
        $message = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->where('role', 'assistant')
            ->orderByDesc('created_at')
            ->first();

        if (! $message) {
            return null;
        }

        // Parse tool_results — the SDK stores them as JSON
        $toolResults = json_decode($message->tool_results ?? '[]', true);

        if (! is_array($toolResults)) {
            return null;
        }

        // Walk the tool_results in order and keep the LAST entry that declares
        // `requires_approval`. If the agent emitted multiple proposals in one
        // turn (e.g. called edit_schedule twice), the final one is canonical.
        $latest = null;
        foreach ($toolResults as $toolResult) {
            $resultContent = $toolResult['content'] ?? $toolResult['result'] ?? null;

            if (! $resultContent) {
                continue;
            }

            $resultData = is_string($resultContent) ? json_decode($resultContent, true) : $resultContent;

            if (! is_array($resultData) || ! ($resultData['requires_approval'] ?? false)) {
                continue;
            }

            $latest = $resultData;
        }

        if ($latest === null) {
            return null;
        }

        $type = ProposalType::tryFrom((string) ($latest['proposal_type'] ?? ''));
        if ($type === null) {
            return null;
        }

        return DB::transaction(function () use ($user, $message, $latest, $type) {
            // Supersede any other pending proposals for this user so at most
            // one pending proposal exists at a time. This is also what makes
            // the edit_schedule flow safe against mid-stream failures: the
            // source proposal is only demoted once the new proposal is
            // actually persisted here.
            CoachProposal::where('user_id', $user->id)
                ->where('status', ProposalStatus::Pending)
                ->update(['status' => ProposalStatus::Rejected]);

            return CoachProposal::create([
                'agent_message_id' => $message->id,
                'user_id' => $user->id,
                'type' => $type,
                'payload' => $latest['payload'],
                'status' => ProposalStatus::Pending,
            ]);
        });
    }

    public function apply(CoachProposal $proposal, User $user): void
    {
        match ($proposal->type) {
            ProposalType::CreateSchedule => $this->applyCreateSchedule($user, $proposal->payload),
            ProposalType::ModifySchedule => $this->applyModifySchedule($user, $proposal->payload),
            ProposalType::EditActivePlan => $this->applyEditActivePlan($user, $proposal->payload),
            ProposalType::AlternativeWeek => $this->applyAlternativeWeek($user, $proposal->payload),
        };

        $proposal->update([
            'status' => ProposalStatus::Accepted,
            'applied_at' => now(),
        ]);

        $this->maybeCompleteOnboarding($proposal, $user);
    }

    private function maybeCompleteOnboarding(CoachProposal $proposal, User $user): void
    {
        if ($user->has_completed_onboarding) {
            return;
        }

        $conversationId = DB::table('agent_conversation_messages')
            ->where('id', $proposal->agent_message_id)
            ->value('conversation_id');

        if (! $conversationId) {
            return;
        }

        $context = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->value('context');

        if ($context === 'onboarding') {
            $user->has_completed_onboarding = true;
            $user->save();
        }
    }

    private function applyCreateSchedule(User $user, array $payload): void
    {
        $distance = $this->normalizeDistance($payload['distance'] ?? null);

        $goalType = GoalType::tryFrom((string) ($payload['goal_type'] ?? ''))
            ?? GoalType::Race;

        $goal = $user->goals()->create([
            'type' => $goalType,
            'name' => $payload['goal_name'],
            'distance' => $distance['distance'],
            'custom_distance_meters' => $distance['custom_distance_meters'],
            'goal_time_seconds' => $payload['goal_time_seconds'] ?? null,
            'target_date' => $payload['target_date'] ?? null,
            'status' => GoalStatus::Planning,
        ]);

        $this->goals->activate($goal);

        $weeks = $payload['schedule']['weeks'] ?? [];
        $today = now()->startOfDay();

        foreach ($weeks as $weekData) {
            $startsAt = $this->resolveWeekStart($weekData['week_number']);

            $week = $goal->trainingWeeks()->create([
                'week_number' => $weekData['week_number'],
                'starts_at' => $startsAt,
                'total_km' => $weekData['total_km'],
                'focus' => $weekData['focus'],
            ]);

            foreach ($weekData['days'] ?? [] as $dayData) {
                $date = $startsAt->copy()->addDays($dayData['day_of_week'] - 1);

                if ($date->lt($today)) {
                    continue;
                }

                $week->trainingDays()->create([
                    'date' => $date,
                    'type' => $dayData['type'],
                    'title' => $dayData['title'],
                    'description' => $dayData['description'] ?? null,
                    'target_km' => $dayData['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $this->normalizeHrZone($dayData['target_heart_rate_zone'] ?? null),
                    'intervals_json' => $this->normalizeIntervals($dayData['intervals'] ?? null),
                    'order' => $dayData['day_of_week'],
                ]);
            }
        }
    }

    /**
     * Normalise a `payload['distance']` value into the Goal model's
     * (distance enum, custom_distance_meters) pair.
     *
     * Accepts:
     * - null / empty                → both null
     * - GoalDistance enum string    → that enum, custom=null
     * - raw meter int (e.g. 10000)  → mapped to enum, custom set if non-standard
     *
     * @return array{distance: ?string, custom_distance_meters: ?int}
     */
    private function normalizeDistance(mixed $value): array
    {
        if ($value === null || $value === '') {
            return ['distance' => null, 'custom_distance_meters' => null];
        }

        if (is_string($value) && GoalDistance::tryFrom($value) !== null) {
            return ['distance' => $value, 'custom_distance_meters' => null];
        }

        if (is_numeric($value)) {
            $meters = (int) $value;

            return match ($meters) {
                5000 => ['distance' => GoalDistance::FiveK->value, 'custom_distance_meters' => null],
                10000 => ['distance' => GoalDistance::TenK->value, 'custom_distance_meters' => null],
                21097 => ['distance' => GoalDistance::HalfMarathon->value, 'custom_distance_meters' => null],
                42195 => ['distance' => GoalDistance::Marathon->value, 'custom_distance_meters' => null],
                default => ['distance' => GoalDistance::Custom->value, 'custom_distance_meters' => $meters],
            };
        }

        return ['distance' => null, 'custom_distance_meters' => null];
    }

    private function resolveWeekStart(int $weekNumber): Carbon
    {
        return now()->startOfWeek()->addWeeks($weekNumber - 1);
    }

    /**
     * Normalise the optional `intervals` array on a training day payload.
     * Returns null if missing/empty so the DB column stays clean for
     * non-interval runs.
     *
     * @param  mixed  $intervals
     * @return array<int, array<string, mixed>>|null
     */
    private function normalizeIntervals($intervals): ?array
    {
        if (! is_array($intervals) || $intervals === []) {
            return null;
        }

        $allowedKinds = ['warmup', 'work', 'recovery', 'cooldown'];
        $out = [];
        foreach ($intervals as $segment) {
            if (! is_array($segment)) {
                continue;
            }

            $kind = $segment['kind'] ?? 'work';
            if (! in_array($kind, $allowedKinds, true)) {
                $kind = 'work';
            }

            $distance = isset($segment['distance_m']) ? (int) $segment['distance_m'] : null;
            if ($distance !== null && $distance <= 0) {
                $distance = null;
            }

            $duration = isset($segment['duration_seconds']) ? (int) $segment['duration_seconds'] : null;
            if ($duration !== null && $duration <= 0) {
                $duration = null;
            }

            $pace = isset($segment['target_pace_seconds_per_km']) ? (int) $segment['target_pace_seconds_per_km'] : null;
            if ($pace !== null && $pace <= 0) {
                $pace = null;
            }

            $out[] = [
                'kind' => $kind,
                'label' => (string) ($segment['label'] ?? 'Segment'),
                'distance_m' => $distance,
                'duration_seconds' => $duration,
                'target_pace_seconds_per_km' => $pace,
            ];
        }

        return $out === [] ? null : $out;
    }

    private function applyModifySchedule(User $user, array $payload): void
    {
        foreach ($payload['changes'] ?? [] as $change) {
            $day = TrainingDay::whereHas('trainingWeek.goal', fn ($q) => $q->where('user_id', $user->id))
                ->find($change['training_day_id']);

            if ($day) {
                $day->update(array_filter([
                    'type' => $change['type'] ?? null,
                    'title' => $change['title'] ?? null,
                    'description' => $change['description'] ?? null,
                    'target_km' => $change['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $change['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $change['target_heart_rate_zone'] ?? null,
                ], fn ($v) => $v !== null));
            }
        }
    }

    /**
     * Apply an in-place edit to the runner's active Goal. Expects a payload
     * in the same `schedule.weeks[].days[]` shape that CreateSchedule uses,
     * plus a `goal_id` pointing at the user's active Goal.
     *
     * Semantics:
     *  - Goal metadata (name, distance, target_date, goal_time_seconds) is
     *    updated where the payload differs from the current row.
     *  - For each week in the payload: upsert TrainingWeek by week_number.
     *  - For each day in the payload: upsert TrainingDay by (week, order).
     *  - Any future TrainingDay (date >= today) that isn't in the payload
     *    and has no logged TrainingResult is DELETED. Past days and days
     *    with results are preserved untouched (history stays intact).
     *
     * @param  array<string, mixed>  $payload
     */
    private function applyEditActivePlan(User $user, array $payload): void
    {
        $goalId = $payload['goal_id'] ?? null;
        if (! $goalId) {
            return;
        }

        $goal = $user->goals()->find($goalId);
        if (! $goal || $goal->status !== GoalStatus::Active) {
            return;
        }

        $this->updateGoalMetadata($goal, $payload);

        $today = now()->startOfDay();
        $weeks = $payload['schedule']['weeks'] ?? [];

        foreach ($weeks as $weekData) {
            $weekNumber = (int) ($weekData['week_number'] ?? 0);
            if ($weekNumber <= 0) {
                continue;
            }

            $week = $goal->trainingWeeks()->firstOrNew(['week_number' => $weekNumber]);
            $week->starts_at = $week->starts_at ?? $this->resolveWeekStart($weekNumber);
            $week->total_km = $weekData['total_km'] ?? $week->total_km ?? 0;
            $week->focus = $weekData['focus'] ?? $week->focus ?? '';
            $week->save();

            $expectedDows = [];
            foreach ($weekData['days'] ?? [] as $dayData) {
                $dow = (int) ($dayData['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                $expectedDows[] = $dow;

                $date = $week->starts_at->copy()->addDays($dow - 1);
                // Skip past dates: we never schedule into the past.
                if ($date->lt($today)) {
                    continue;
                }

                $fields = [
                    'date' => $date,
                    'type' => $dayData['type'],
                    'title' => $dayData['title'],
                    'description' => $dayData['description'] ?? null,
                    'target_km' => $dayData['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $this->normalizeHrZone($dayData['target_heart_rate_zone'] ?? null),
                    'intervals_json' => $this->normalizeIntervals($dayData['intervals'] ?? null),
                ];

                $existing = $week->trainingDays()->where('order', $dow)->first();
                if ($existing) {
                    $existing->update($fields);
                } else {
                    $week->trainingDays()->create(array_merge($fields, ['order' => $dow]));
                }
            }

            // Delete only FUTURE days that aren't in the expected list and
            // don't have a logged result. Past days and completed workouts
            // are preserved.
            $week->trainingDays()
                ->whereNotIn('order', $expectedDows)
                ->whereDoesntHave('result')
                ->where('date', '>=', $today)
                ->delete();
        }
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function updateGoalMetadata(Goal $goal, array $payload): void
    {
        $dirty = [];

        if (array_key_exists('goal_name', $payload) && $payload['goal_name'] !== null && $payload['goal_name'] !== $goal->name) {
            $dirty['name'] = $payload['goal_name'];
        }
        if (array_key_exists('distance', $payload)) {
            $distance = $this->normalizeDistance($payload['distance']);
            $dirty['distance'] = $distance['distance'];
            $dirty['custom_distance_meters'] = $distance['custom_distance_meters'];
        }
        if (array_key_exists('goal_time_seconds', $payload) && $payload['goal_time_seconds'] !== $goal->goal_time_seconds) {
            $dirty['goal_time_seconds'] = $payload['goal_time_seconds'];
        }
        if (array_key_exists('target_date', $payload)) {
            $dirty['target_date'] = $payload['target_date'];
        }

        if ($dirty !== []) {
            $goal->update($dirty);
        }
    }

    private function applyAlternativeWeek(User $user, array $payload): void
    {
        $goal = $user->goals()->findOrFail($payload['goal_id']);
        $week = $goal->trainingWeeks()->where('week_number', $payload['week_number'])->firstOrFail();
        $today = now()->startOfDay();

        $week->trainingDays()->whereDoesntHave('result')->delete();

        foreach ($payload['alternative_days'] ?? [] as $dayData) {
            $date = $week->starts_at->copy()->addDays($dayData['day_of_week'] - 1);

            if ($date->lt($today)) {
                continue;
            }

            $week->trainingDays()->create([
                'date' => $date,
                'type' => $dayData['type'],
                'title' => $dayData['title'],
                'description' => $dayData['description'] ?? null,
                'target_km' => $dayData['target_km'] ?? null,
                'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                'target_heart_rate_zone' => $this->normalizeHrZone($dayData['target_heart_rate_zone'] ?? null),
                'order' => $dayData['day_of_week'],
            ]);
        }
    }

    /**
     * Normalise a heart-rate zone value into an int 1-5 (DB column type).
     *
     * Accepts integers, numeric strings ("2"), or "Z2" / "z5" prefixes
     * (the onboarding prompt sometimes emits the "Zn" form). Returns null
     * for anything outside 1-5.
     */
    private function normalizeHrZone(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_string($value)) {
            $value = preg_replace('/^[Zz]/', '', $value);
        }

        if (! is_numeric($value)) {
            return null;
        }

        $int = (int) $value;

        return ($int >= 1 && $int <= 5) ? $int : null;
    }
}
