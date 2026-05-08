<?php

namespace App\Services;

use App\Ai\Agents\OnboardingAgent;
use App\Enums\ProposalStatus;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use RuntimeException;

class OnboardingPlanGeneratorService
{
    public function __construct(
        private readonly ProposalService $proposals,
    ) {}

    /**
     * Generate the runner's first training plan via the deterministic
     * `OnboardingAgent` → `BuildOnboardingPlan` pipeline.
     *
     * The agent receives a priming message with the form fields, calls
     * the single tool exactly once, then emits a friendly one-sentence
     * reply. The tool itself owns the snapshot → builder → optimizer →
     * proposal-persist sequence; no LLM authors the schedule JSON. End
     * to end this is one Anthropic round-trip (the friendly reply),
     * dominated by 1-3 seconds of network latency rather than 60-110s
     * of agent looping.
     *
     * @param  array<string, mixed>  $formData
     * @return array{conversation_id: string, proposal_id: int, weeks: int}
     */
    public function generate(User $user, array $formData): array
    {
        Log::info(sprintf(
            '[onboarding:start] user_id=%d goal_type=%s distance=%s target_date=%s days=%s weekdays=%s style=%s',
            $user->id,
            $formData['goal_type'] ?? 'null',
            $formData['distance_meters'] ?? 'null',
            $formData['target_date'] ?? 'null',
            $formData['days_per_week'] ?? 'null',
            isset($formData['preferred_weekdays']) && is_array($formData['preferred_weekdays'])
                ? implode(',', $formData['preferred_weekdays'])
                : 'any',
            $formData['coach_style'] ?? 'null',
        ));

        // Kill any residual pending proposals (e.g. from an interrupted
        // previous onboarding session). A fresh onboarding always starts
        // from a clean slate.
        CoachProposal::where('user_id', $user->id)
            ->where('status', ProposalStatus::Pending)
            ->update(['status' => ProposalStatus::Rejected]);

        $conversationId = (string) Str::uuid();
        $now = now();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Your training plan',
            'context' => 'onboarding',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $primingMessage = $this->buildPrimingMessage($formData);

        $promptStartedAt = microtime(true);

        OnboardingAgent::make(user: $user)
            ->continue($conversationId, as: $user)
            ->prompt($primingMessage);

        Log::info(sprintf(
            '[agent:prompt] ctx=onboarding user_id=%d duration_ms=%d message_bytes=%d',
            $user->id,
            (int) round((microtime(true) - $promptStartedAt) * 1000),
            strlen($primingMessage),
        ));

        $proposal = $this->proposals->detectProposalFromConversation($user, $conversationId);

        if (! $proposal) {
            Log::error('OnboardingPlanGenerator: agent completed without producing a proposal', [
                'user_id' => $user->id,
                'conversation_id' => $conversationId,
            ]);

            throw new RuntimeException('Onboarding agent did not produce a plan proposal.');
        }

        return [
            'conversation_id' => $conversationId,
            'proposal_id' => $proposal->id,
            'weeks' => count($proposal->payload['schedule']['weeks'] ?? []),
        ];
    }

    /**
     * Compact priming message — just the form fields. The 12-month
     * profile metrics that used to live here are GONE; the new builder
     * derives a recent fitness snapshot itself inside the tool, no
     * input from the prompt needed.
     *
     * @param  array<string, mixed>  $formData
     */
    private function buildPrimingMessage(array $formData): string
    {
        $weekdays = isset($formData['preferred_weekdays']) && is_array($formData['preferred_weekdays'])
            ? implode(',', array_map('intval', $formData['preferred_weekdays']))
            : 'null';

        $runTypeRanking = isset($formData['run_type_preferences']) && is_array($formData['run_type_preferences']) && $formData['run_type_preferences'] !== []
            ? implode(' > ', array_map('strval', $formData['run_type_preferences']))
            : 'null';

        $rawNotes = $formData['additional_notes'] ?? $formData['notes'] ?? null;
        $hasNotes = is_string($rawNotes) && trim($rawNotes) !== '';

        $lines = [
            'Onboarding form complete. Build the plan first, then check the additional_notes block at the bottom of this message and decide whether to adjust.',
            '',
            'Form data:',
            '- goal_type: '.($formData['goal_type'] ?? 'null'),
            '- goal_name: '.($formData['goal_name'] ?? 'null'),
            '- distance_meters: '.($formData['distance_meters'] ?? 'null'),
            '- target_date: '.($formData['target_date'] ?? 'null'),
            '- goal_time_seconds: '.($formData['goal_time_seconds'] ?? 'null'),
            '- pr_current_seconds: '.($formData['pr_current_seconds'] ?? 'null'),
            '- days_per_week: '.($formData['days_per_week'] ?? 'null'),
            '- preferred_weekdays: '.$weekdays,
            '- run_type_preferences (gold→last): '.$runTypeRanking,
            '- coach_style: '.($formData['coach_style'] ?? 'null'),
            '',
            $hasNotes
                ? 'ADDITIONAL NOTES (read carefully — translate any specific training preferences into adjust_onboarding_plan ops AFTER build_onboarding_plan returns):'
                : 'ADDITIONAL NOTES: none — skip adjust_onboarding_plan and reply with one friendly sentence.',
            $hasNotes ? '"'.trim($rawNotes).'"' : '',
        ];

        return implode("\n", array_filter($lines, fn ($line) => $line !== ''));
    }
}
