<?php

namespace App\Jobs;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\GoalType;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RunOnboardingPlanAgentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public string $conversationId,
        public int $userId,
    ) {}

    public function handle(ProposalService $proposalService): void
    {
        $convoRow = DB::table('agent_conversations')->where('id', $this->conversationId)->first();
        if (! $convoRow) {
            return;
        }

        $user = User::findOrFail($this->userId);
        $meta = json_decode($convoRow->meta, true) ?? [];
        $seed = $this->buildSeedMessage($meta);

        RunCoachAgent::make(user: $user)
            ->continue($this->conversationId, as: $user)
            ->prompt($seed);

        $proposal = $proposalService->detectProposalFromConversation($user, $this->conversationId);

        if ($proposal === null) {
            $this->appendErrorMessages();
            $this->setStep($meta, 'plan_failed');

            return;
        }

        $this->setStep($meta, 'plan_proposed');
    }

    public function failed(\Throwable $e): void
    {
        $convoRow = DB::table('agent_conversations')->where('id', $this->conversationId)->first();
        if (! $convoRow) {
            return;
        }

        $meta = json_decode($convoRow->meta ?? '{}', true) ?? [];
        $this->appendErrorMessages();
        $this->setStep($meta, 'plan_failed');
    }

    private function appendErrorMessages(): void
    {
        $userId = DB::table('agent_conversations')->where('id', $this->conversationId)->value('user_id');
        $now = now();

        DB::table('agent_conversation_messages')->insert([
            'id' => (string) Str::uuid(),
            'conversation_id' => $this->conversationId,
            'user_id' => $userId,
            'agent' => 'App\Ai\Agents\RunCoachAgent',
            'role' => 'assistant',
            'content' => 'Something went wrong generating your plan. Tap below to retry.',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => json_encode(['message_type' => 'text', 'message_payload' => []]),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('agent_conversation_messages')->insert([
            'id' => (string) Str::uuid(),
            'conversation_id' => $this->conversationId,
            'user_id' => $userId,
            'agent' => 'App\Ai\Agents\RunCoachAgent',
            'role' => 'assistant',
            'content' => '',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => json_encode([
                'message_type' => 'chip_suggestions',
                'message_payload' => [
                    'chips' => [['label' => 'Retry', 'value' => 'retry_plan']],
                ],
            ]),
            'created_at' => $now->copy()->addSecond(),
            'updated_at' => $now->copy()->addSecond(),
        ]);
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    private function setStep(array &$meta, string $step): void
    {
        $meta['onboarding_step'] = $step;
        DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);
    }

    private function buildSeedMessage(array $meta): string
    {
        $path = $meta['path'] ?? GoalType::Race->value;
        $coachStyle = $meta['coach_style'] ?? 'balanced';

        if ($path === GoalType::Race->value) {
            return 'The user completed onboarding. Path: '.GoalType::Race->value.'. Raw race input: "'
                .($meta['race_details_raw'] ?? '').'". Coach style: '.$coachStyle.'. '
                ."Now call CreateSchedule with goal_type='".GoalType::Race->value."', parsing the race input for goal_name, target_date, goal_time_seconds, distance. "
                .'Use the running profile to size the plan appropriately.';
        }

        if ($path === GoalType::GeneralFitness->value) {
            $days = $meta['days_per_week'] ?? 3;

            return 'The user completed onboarding. Path: '.GoalType::GeneralFitness->value.'. Days/week: '.$days.'. Coach style: '.$coachStyle.'. '
                ."Call CreateSchedule with goal_type='".GoalType::GeneralFitness->value."', goal_name='General fitness', target_date=null, distance=null. "
                ."Design a base-building weekly pattern with {$days} runs/week.";
        }

        if ($path === GoalType::PrAttempt->value) {
            $distance = $meta['distance'] ?? '5k';
            $prRaw = $meta['pr_target_raw'] ?? '';
            $days = $meta['days_per_week'] ?? 4;

            return 'The user completed onboarding. Path: '.GoalType::PrAttempt->value.'. Distance: '.$distance.'. PR/target raw: "'.$prRaw.'". Days/week: '.$days.'. Coach style: '.$coachStyle.'. '
                ."Call CreateSchedule with goal_type='".GoalType::PrAttempt->value."', goal_name='Get faster at {$distance}', target_date=null, distance='{$distance}'. "
                .'Parse the PR/target string for goal_time_seconds. Design a speed-focused block.';
        }

        return 'Generate a training plan based on onboarding context.';
    }
}
