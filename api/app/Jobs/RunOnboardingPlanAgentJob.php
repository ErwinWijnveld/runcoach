<?php

namespace App\Jobs;

use App\Ai\Agents\RunCoachAgent;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;

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

        $proposalService->detectProposalFromConversation($user, $this->conversationId);

        $meta['onboarding_step'] = 'plan_proposed';
        DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);
    }

    public function failed(\Throwable $e): void
    {
        $convoRow = DB::table('agent_conversations')->where('id', $this->conversationId)->first();
        if (! $convoRow) {
            return;
        }

        $meta = json_decode($convoRow->meta ?? '{}', true) ?? [];
        $meta['onboarding_step'] = 'plan_failed';

        DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);
    }

    private function buildSeedMessage(array $meta): string
    {
        $path = $meta['path'] ?? 'race';
        $coachStyle = $meta['coach_style'] ?? 'balanced';

        if ($path === 'race') {
            return 'The user completed onboarding. Path: race. Raw race input: "'
                .($meta['race_details_raw'] ?? '').'". Coach style: '.$coachStyle.'. '
                ."Now call CreateSchedule with goal_type='race', parsing the race input for goal_name, target_date, goal_time_seconds, distance. "
                .'Use the running profile to size the plan appropriately.';
        }

        if ($path === 'general_fitness') {
            $days = $meta['days_per_week'] ?? 3;

            return 'The user completed onboarding. Path: general_fitness. Days/week: '.$days.'. Coach style: '.$coachStyle.'. '
                ."Call CreateSchedule with goal_type='general_fitness', goal_name='General fitness', target_date=null, distance=null. "
                ."Design a base-building weekly pattern with {$days} runs/week.";
        }

        if ($path === 'pr_attempt') {
            $distance = $meta['distance'] ?? '5k';
            $prRaw = $meta['pr_target_raw'] ?? '';
            $days = $meta['days_per_week'] ?? 4;

            return 'The user completed onboarding. Path: pr_attempt. Distance: '.$distance.'. PR/target raw: "'.$prRaw.'". Days/week: '.$days.'. Coach style: '.$coachStyle.'. '
                ."Call CreateSchedule with goal_type='pr_attempt', goal_name='Get faster at {$distance}', target_date=null, distance='{$distance}'. "
                .'Parse the PR/target string for goal_time_seconds. Design a speed-focused block.';
        }

        return 'Generate a training plan based on onboarding context.';
    }
}
