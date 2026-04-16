<?php

namespace App\Jobs;

use App\Enums\GoalType;
use App\Models\User;
use App\Services\RunningProfileService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AnalyzeRunningProfileJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public string $conversationId,
        public int $userId,
    ) {}

    public function handle(RunningProfileService $service): void
    {
        $conversation = DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->firstOrFail();

        $user = User::findOrFail($this->userId);

        $profile = $service->analyze($user);

        $this->appendMessage($conversation->id, $conversation->user_id, 'text', $profile->narrative_summary);
        $this->appendMessage($conversation->id, $conversation->user_id, 'stats_card', null, [
            'metrics' => [
                'weekly_avg_km' => $profile->metrics['weekly_avg_km'] ?? 0,
                'weekly_avg_runs' => $profile->metrics['weekly_avg_runs'] ?? 0,
                'avg_pace_seconds_per_km' => $profile->metrics['avg_pace_seconds_per_km'] ?? 0,
                'session_avg_duration_seconds' => $profile->metrics['session_avg_duration_seconds'] ?? 0,
            ],
        ]);
        $this->appendMessage($conversation->id, $conversation->user_id, 'text', "Anything you're training for, or want to work toward?");
        $this->appendMessage($conversation->id, $conversation->user_id, 'chip_suggestions', null, [
            'chips' => [
                ['label' => 'Race coming up!', 'value' => GoalType::Race->value],
                ['label' => 'General fitness', 'value' => GoalType::GeneralFitness->value],
                ['label' => 'Get faster', 'value' => GoalType::PrAttempt->value],
            ],
        ]);

        $meta = json_decode($conversation->meta ?? '{}', true) ?? [];
        $meta['onboarding_step'] = 'awaiting_branch';

        DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);
    }

    public function failed(\Throwable $e): void
    {
        $conversation = DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->first();

        if (! $conversation) {
            return;
        }

        $meta = json_decode($conversation->meta ?? '{}', true) ?? [];
        $meta['onboarding_step'] = 'analysis_failed';

        DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);

        $this->appendMessage($conversation->id, $conversation->user_id, 'loading_card_error', null, [
            'label' => "I couldn't reach Strava. Retry?",
            'retry' => true,
        ]);
    }

    private function appendMessage(string $conversationId, int $userId, string $type, ?string $content = null, array $payload = []): void
    {
        DB::table('agent_conversation_messages')->insert([
            'id' => (string) Str::uuid(),
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'agent' => 'App\Ai\Agents\RunCoachAgent',
            'role' => 'assistant',
            'content' => $content ?? '',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => json_encode([
                'message_type' => $type,
                'message_payload' => $payload,
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
