<?php

namespace App\Services;

use App\Ai\Agents\OnboardingPlanAgent;
use App\Enums\GoalType;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use RuntimeException;

class OnboardingPlanGeneratorService
{
    public function __construct(
        private readonly OnboardingPlanPromptBuilder $promptBuilder,
        private readonly RunningProfileService $profiles,
    ) {}

    /**
     * Generate a training plan from the onboarding-form payload.
     *
     * Side effects:
     *  - Calls the LLM via OnboardingPlanAgent.
     *  - Creates an `agent_conversations` row with context='onboarding'.
     *  - Seeds one assistant message (content + tool_results JSON) so the
     *    Flutter coach chat can hydrate it as an opening message + proposal.
     *  - Creates a pending CoachProposal.
     *
     * @param  array<string, mixed>  $formData
     * @return array{conversation_id: string, proposal_id: int, weeks: int}
     */
    public function generate(User $user, array $formData): array
    {
        $profile = $this->profiles->getOrAnalyze($user);
        $metrics = $profile?->metrics ?? [];

        $preferredWeekdays = $formData['preferred_weekdays'] ?? null;
        if (is_array($preferredWeekdays)) {
            $preferredWeekdays = array_values(array_unique(array_map('intval', $preferredWeekdays)));
            sort($preferredWeekdays);
            if (count($preferredWeekdays) === 0) {
                $preferredWeekdays = null;
            }
        } else {
            $preferredWeekdays = null;
        }

        $prompt = $this->promptBuilder->build(
            goalType: $formData['goal_type'],
            distanceMeters: $formData['distance_meters'] ?? null,
            goalName: $formData['goal_name'] ?? null,
            targetDate: $formData['target_date'] ?? null,
            goalTimeSeconds: $formData['goal_time_seconds'] ?? null,
            daysPerWeek: (int) $formData['days_per_week'],
            coachStyle: $formData['coach_style'],
            prCurrentSeconds: $formData['pr_current_seconds'] ?? null,
            profileMetrics: $metrics,
            todayIso: now()->toDateString(),
            todayWeekday: (int) now()->isoWeekday(),
            preferredWeekdays: $preferredWeekdays,
            additionalNotes: $formData['additional_notes'] ?? null,
        );

        $response = OnboardingPlanAgent::make()->prompt($prompt);

        $schedule = $this->parseScheduleJson($response->text);

        $payload = [
            'goal_type' => match ($formData['goal_type']) {
                'race' => GoalType::Race->value,
                'pr' => GoalType::PrAttempt->value,
                default => GoalType::GeneralFitness->value,
            },
            'goal_name' => $this->resolveGoalName($formData),
            'distance' => $formData['distance_meters'] ?? null,
            'goal_time_seconds' => $formData['goal_time_seconds'] ?? null,
            'target_date' => $formData['target_date'] ?? null,
            'schedule' => $schedule,
        ];

        $conversationId = (string) Str::uuid();
        $messageId = (string) Str::uuid();

        DB::transaction(function () use ($user, $conversationId, $messageId, $payload): void {
            $now = now();

            DB::table('agent_conversations')->insert([
                'id' => $conversationId,
                'user_id' => $user->id,
                'title' => 'Your training plan',
                'context' => 'onboarding',
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('agent_conversation_messages')->insert([
                'id' => $messageId,
                'conversation_id' => $conversationId,
                'user_id' => $user->id,
                'agent' => 'App\\Ai\\Agents\\RunCoachAgent',
                'role' => 'assistant',
                'content' => "Based on your performance over the last year and your goals, I've built a plan for you. Take a look below. Tap Accept if it looks right, or Adjust if you'd like me to tweak anything.",
                'attachments' => '[]',
                'tool_calls' => '[]',
                'tool_results' => json_encode([
                    [
                        'tool_name' => ProposalType::CreateSchedule->value,
                        'result' => [
                            'requires_approval' => true,
                            'proposal_type' => ProposalType::CreateSchedule->value,
                            'payload' => $payload,
                        ],
                    ],
                ]),
                'usage' => '{}',
                'meta' => '{}',
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        });

        $proposal = CoachProposal::create([
            'agent_message_id' => $messageId,
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => $payload,
            'status' => ProposalStatus::Pending,
        ]);

        return [
            'conversation_id' => $conversationId,
            'proposal_id' => $proposal->id,
            'weeks' => count($schedule['weeks'] ?? []),
        ];
    }

    /**
     * @return array{weeks: array<int, array<string, mixed>>}
     */
    private function parseScheduleJson(string $text): array
    {
        $cleaned = trim($text);
        // Strip leading/trailing markdown code fences if present.
        $cleaned = preg_replace('/^```(?:json)?\s*|\s*```$/m', '', $cleaned) ?? $cleaned;
        $cleaned = trim($cleaned);

        $parsed = json_decode($cleaned, true);

        if (! is_array($parsed) || ! isset($parsed['weeks']) || ! is_array($parsed['weeks'])) {
            Log::error('OnboardingPlanGenerator: invalid JSON returned by agent', [
                'text_preview' => Str::limit($text, 500),
            ]);

            throw new RuntimeException('Generator returned invalid schedule JSON.');
        }

        return $parsed;
    }

    /**
     * @param  array<string, mixed>  $formData
     */
    private function resolveGoalName(array $formData): string
    {
        $explicit = $formData['goal_name'] ?? null;

        if (is_string($explicit) && $explicit !== '') {
            return $explicit;
        }

        return match ($formData['goal_type']) {
            'race' => 'Race',
            'pr' => 'Personal record attempt',
            'weight_loss' => 'Weight loss',
            default => 'General fitness',
        };
    }
}
