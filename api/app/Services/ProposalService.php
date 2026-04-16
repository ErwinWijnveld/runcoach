<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\TrainingDay;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ProposalService
{
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

        // Look through tool results for proposal data
        foreach ($toolResults as $toolResult) {
            $resultContent = $toolResult['content'] ?? $toolResult['result'] ?? null;

            if (! $resultContent) {
                continue;
            }

            // The result might be a JSON string
            $resultData = is_string($resultContent) ? json_decode($resultContent, true) : $resultContent;

            if (! is_array($resultData) || ! ($resultData['requires_approval'] ?? false)) {
                continue;
            }

            return CoachProposal::create([
                'agent_message_id' => $message->id,
                'user_id' => $user->id,
                'type' => ProposalType::from($resultData['proposal_type']),
                'payload' => $resultData['payload'],
                'status' => ProposalStatus::Pending,
            ]);
        }

        return null;
    }

    public function apply(CoachProposal $proposal, User $user): void
    {
        match ($proposal->type) {
            ProposalType::CreateSchedule => $this->applyCreateSchedule($user, $proposal->payload),
            ProposalType::ModifySchedule => $this->applyModifySchedule($user, $proposal->payload),
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
        $goal = $user->goals()->create([
            'type' => GoalType::from($payload['goal_type'] ?? 'race'),
            'name' => $payload['goal_name'],
            'distance' => $payload['distance'] ?? null,
            'goal_time_seconds' => $payload['goal_time_seconds'] ?? null,
            'target_date' => $payload['target_date'] ?? null,
            'status' => GoalStatus::Active,
        ]);

        $weeks = $payload['schedule']['weeks'] ?? [];

        foreach ($weeks as $weekData) {
            $startsAt = $this->resolveWeekStart($payload['target_date'] ?? null, count($weeks), $weekData['week_number']);

            $week = $goal->trainingWeeks()->create([
                'week_number' => $weekData['week_number'],
                'starts_at' => $startsAt,
                'total_km' => $weekData['total_km'],
                'focus' => $weekData['focus'],
            ]);

            foreach ($weekData['days'] ?? [] as $dayData) {
                $week->trainingDays()->create([
                    'date' => $startsAt->copy()->addDays($dayData['day_of_week'] - 1),
                    'type' => $dayData['type'],
                    'title' => $dayData['title'],
                    'description' => $dayData['description'] ?? null,
                    'target_km' => $dayData['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $dayData['target_heart_rate_zone'] ?? null,
                    'order' => $dayData['day_of_week'],
                ]);
            }
        }
    }

    private function resolveWeekStart(?string $targetDate, int $totalWeeks, int $weekNumber): Carbon
    {
        if ($targetDate !== null) {
            return Carbon::parse($targetDate)
                ->subWeeks($totalWeeks - $weekNumber + 1)
                ->startOfWeek();
        }

        return now()
            ->addWeeks($weekNumber - 1)
            ->startOfWeek();
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

    private function applyAlternativeWeek(User $user, array $payload): void
    {
        $goal = $user->goals()->findOrFail($payload['goal_id']);
        $week = $goal->trainingWeeks()->where('week_number', $payload['week_number'])->firstOrFail();

        $week->trainingDays()->whereDoesntHave('result')->delete();

        foreach ($payload['alternative_days'] ?? [] as $dayData) {
            $week->trainingDays()->create([
                'date' => $week->starts_at->copy()->addDays($dayData['day_of_week'] - 1),
                'type' => $dayData['type'],
                'title' => $dayData['title'],
                'description' => $dayData['description'] ?? null,
                'target_km' => $dayData['target_km'] ?? null,
                'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                'target_heart_rate_zone' => $dayData['target_heart_rate_zone'] ?? null,
                'order' => $dayData['day_of_week'],
            ]);
        }
    }
}
