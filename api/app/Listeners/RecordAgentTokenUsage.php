<?php

namespace App\Listeners;

use App\Ai\Agents\ActivityFeedbackAgent;
use App\Ai\Agents\RunCoachAgent;
use App\Ai\Agents\RunningNarrativeAgent;
use App\Ai\Agents\WeeklyInsightAgent;
use App\Models\TokenUsage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Events\AgentPrompted;
use Laravel\Ai\Events\AgentStreamed;

class RecordAgentTokenUsage
{
    public function handle(AgentPrompted|AgentStreamed $event): void
    {
        $usage = $event->response->usage ?? null;

        if ($usage === null) {
            return;
        }

        $totalTokens = $usage->promptTokens + $usage->completionTokens;

        if ($totalTokens === 0) {
            return;
        }

        $agent = $event->prompt->agent;

        TokenUsage::create([
            'invocation_id' => $event->invocationId,
            'user_id' => $this->resolveUserId($agent),
            'conversation_id' => $this->resolveConversationId($agent),
            'agent_class' => $agent::class,
            'context' => $this->resolveContext($agent),
            'provider' => $event->response->meta->provider ?? null,
            'model' => $event->response->meta->model ?? null,
            'prompt_tokens' => $usage->promptTokens,
            'completion_tokens' => $usage->completionTokens,
            'cache_write_input_tokens' => $usage->cacheWriteInputTokens,
            'cache_read_input_tokens' => $usage->cacheReadInputTokens,
            'reasoning_tokens' => $usage->reasoningTokens,
            'total_tokens' => $totalTokens,
        ]);
    }

    private function resolveUserId(object $agent): ?int
    {
        if ($this->usesRemembersConversations($agent)) {
            $participant = $agent->conversationParticipant();
            if ($participant && isset($participant->id) && is_int($participant->id)) {
                return $participant->id;
            }
        }

        // Fallback: read a private `$user` property if present (e.g. RunCoachAgent, tools' user).
        $reflection = new \ReflectionClass($agent);
        if ($reflection->hasProperty('user')) {
            $prop = $reflection->getProperty('user');
            $prop->setAccessible(true);
            $user = $prop->getValue($agent);
            if ($user && isset($user->id) && is_int($user->id)) {
                return $user->id;
            }
        }

        return null;
    }

    private function resolveConversationId(object $agent): ?string
    {
        if ($this->usesRemembersConversations($agent)) {
            return $agent->currentConversation();
        }

        return null;
    }

    private function resolveContext(object $agent): string
    {
        if ($agent instanceof RunCoachAgent) {
            $conversationId = $this->resolveConversationId($agent);

            if ($conversationId) {
                $context = DB::table('agent_conversations')
                    ->where('id', $conversationId)
                    ->value('context');

                if ($context === 'onboarding') {
                    return 'onboarding';
                }
            }

            return 'coach';
        }

        return match (true) {
            $agent instanceof ActivityFeedbackAgent => 'activity_feedback',
            $agent instanceof WeeklyInsightAgent => 'weekly_insight',
            $agent instanceof RunningNarrativeAgent => 'running_narrative',
            default => Str::snake(class_basename($agent)),
        };
    }

    private function usesRemembersConversations(object $agent): bool
    {
        $traits = class_uses_recursive($agent);

        return in_array(RemembersConversations::class, $traits, true);
    }
}
