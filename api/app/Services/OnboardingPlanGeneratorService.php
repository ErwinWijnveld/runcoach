<?php

namespace App\Services;

use App\Ai\Agents\RunCoachAgent;
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
        private readonly RunningProfileService $profiles,
        private readonly ProposalService $proposals,
    ) {}

    /**
     * Generate the runner's first training plan by driving the shared
     * agentic loop: an `agent_conversations` row with context=`onboarding`
     * is seeded, a priming user message carrying the form data is sent
     * through `RunCoachAgent`, and the agent responds by calling
     * `create_schedule` → `verify_plan` (→ `edit_schedule` → `verify_plan`
     * if the auditor flagged issues) until the loop settles or the cap
     * hits.
     *
     * Same pipeline the coach-chat uses, which means the optimizer runs
     * automatically inside `CreateSchedule::handle` and the verify-edit
     * retry loop is owned by the agent — no bespoke JSON parsing, no
     * duplicate verifier orchestration.
     *
     * @param  array<string, mixed>  $formData
     * @return array{conversation_id: string, proposal_id: int, weeks: int}
     */
    public function generate(User $user, array $formData): array
    {
        $profile = $this->profiles->getOrAnalyze($user);
        $metrics = $profile?->metrics ?? [];

        $preferredWeekdays = $this->normalizePreferredWeekdays($formData['preferred_weekdays'] ?? null);

        Log::info(sprintf(
            '[onboarding:start] user_id=%d goal_type=%s distance=%s target_date=%s days=%s weekdays=%s style=%s',
            $user->id,
            $formData['goal_type'] ?? 'null',
            $formData['distance_meters'] ?? 'null',
            $formData['target_date'] ?? 'null',
            $formData['days_per_week'] ?? 'null',
            $preferredWeekdays ? implode(',', $preferredWeekdays) : 'any',
            $formData['coach_style'] ?? 'null',
        ));

        // Kill any residual pending proposals (e.g. from an interrupted
        // previous onboarding session). A fresh onboarding always starts
        // from a clean slate — otherwise the agent's auto-target logic in
        // verify_plan / edit_schedule could pick up a stale proposal mid
        // loop and end up mashing the old plan together with the new one.
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

        $primingMessage = $this->buildPrimingMessage($formData, $metrics, $preferredWeekdays);

        $promptStartedAt = microtime(true);

        RunCoachAgent::make(user: $user)
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
     * @param  mixed  $raw
     * @return list<int>|null
     */
    private function normalizePreferredWeekdays($raw): ?array
    {
        if (! is_array($raw)) {
            return null;
        }

        $normalized = array_values(array_unique(array_map('intval', $raw)));
        sort($normalized);

        return count($normalized) === 0 ? null : $normalized;
    }

    /**
     * @param  array<string, mixed>  $formData
     * @param  array<string, mixed>  $metrics
     * @param  array<int, int>|null  $preferredWeekdays
     */
    private function buildPrimingMessage(array $formData, array $metrics, ?array $preferredWeekdays): string
    {
        $goalType = match ($formData['goal_type']) {
            'race' => 'race',
            'pr' => 'pr_attempt',
            default => 'general_fitness',
        };

        $goalName = $this->resolveGoalName($formData);
        $weekdays = $preferredWeekdays ? implode(',', $preferredWeekdays) : 'any';

        $lines = [
            'Onboarding form complete. Generate my plan now — do not ask follow-up questions, all fields are filled in.',
            '',
            'Form data:',
            "- goal_type: {$goalType}",
            "- goal_name: {$goalName}",
            '- distance (meters): '.($formData['distance_meters'] ?? 'null'),
            '- target_date: '.($formData['target_date'] ?? 'null'),
            '- goal_time_seconds: '.($formData['goal_time_seconds'] ?? 'null'),
            '- days_per_week: '.$formData['days_per_week'],
            "- preferred_weekdays (1=Mon…7=Sun): {$weekdays}",
            '- coach_style: '.$formData['coach_style'],
            '- additional_notes: '.($this->formatNotes($formData['additional_notes'] ?? null)),
            '',
            'My 12-month profile:',
            '- weekly_avg_km: '.($metrics['weekly_avg_km'] ?? 'unknown'),
            '- avg_pace_seconds_per_km: '.($metrics['avg_pace_seconds_per_km'] ?? 'unknown'),
            '- weekly_avg_runs: '.($metrics['weekly_avg_runs'] ?? 'unknown'),
            '- consistency_score: '.($metrics['consistency_score'] ?? 'unknown').'/100',
            '- long_run_trend: '.($metrics['long_run_trend'] ?? 'unknown'),
            '- pace_trend: '.($metrics['pace_trend'] ?? 'unknown'),
        ];

        return implode("\n", $lines);
    }

    private function formatNotes(mixed $notes): string
    {
        if (! is_string($notes) || trim($notes) === '') {
            return 'none';
        }

        return '"'.trim($notes).'"';
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
