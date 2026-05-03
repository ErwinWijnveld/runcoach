<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Log;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Streaming\Events\ToolResult as ToolResultEvent;
use Throwable;

/**
 * Shared SSE streaming wrapper for any conversational agent. Both the
 * coach chat and the per-workout chat funnel through here so they emit
 * the same Vercel-protocol events (`text-delta`, `tool-input-available`,
 * `data-stats`, `data-chips`, `data-proposal`, `data-handoff`, `error`,
 * `[DONE]`).
 *
 * The caller writes the response headers + opens the streamed response;
 * this service handles the per-event echo + ob_flush/flush dance and
 * the post-stream proposal detection.
 */
class AgentStreamingService
{
    public function __construct(private readonly ProposalService $proposals) {}

    /**
     * Stream `$content` through `$agent` (already bound to a conversation),
     * emitting SSE chunks straight to the response buffer. Safe to call
     * inside `response()->stream(...)`.
     *
     * @param  string  $logContext  short label included in the [agent:prompt] log line (e.g. `coach`, `workout`).
     */
    public function stream(
        Agent $agent,
        string $conversationId,
        User $user,
        string $content,
        string $logContext = 'coach',
    ): void {
        ignore_user_abort(true);
        set_time_limit(0);

        $promptStartedAt = microtime(true);

        try {
            $stream = $agent->stream($content);

            foreach ($stream as $event) {
                $payload = $event->toVercelProtocolArray();
                if (! empty($payload)) {
                    $this->emit($payload);
                }

                if ($event instanceof ToolResultEvent) {
                    $this->emitToolDisplayEvents($event);
                }
            }

            $proposal = $this->proposals->detectProposalFromConversation($user, $conversationId);
            if ($proposal) {
                $this->emit([
                    'type' => 'data-proposal',
                    'data' => $proposal->toArray(),
                ]);
            }

            Log::info(sprintf(
                '[agent:prompt] ctx=%s user_id=%d duration_ms=%d message_bytes=%d',
                $logContext,
                $user->id,
                (int) round((microtime(true) - $promptStartedAt) * 1000),
                strlen($content),
            ));
        } catch (Throwable $e) {
            Log::error('['.$logContext.' stream] '.get_class($e).': '.$e->getMessage(), [
                'conversation_id' => $conversationId,
                'user_id' => $user->id,
            ]);
            $this->emit([
                'type' => 'error',
                'errorText' => $this->humanizeStreamError($e),
            ]);
        }

        $this->emitRaw("[DONE]\n\n");
    }

    /**
     * Inspect a tool-result event for the lightweight UI display markers
     * (`stats_card`, `chip_suggestions`, `handoff`) and forward each as a
     * dedicated `data-*` event the Flutter clients already understand.
     */
    private function emitToolDisplayEvents(ToolResultEvent $event): void
    {
        $result = is_string($event->toolResult->result)
            ? json_decode($event->toolResult->result, true)
            : $event->toolResult->result;

        if (! is_array($result)) {
            return;
        }

        $display = $result['display'] ?? null;
        if ($display === 'stats_card') {
            $this->emit([
                'type' => 'data-stats',
                'data' => ['metrics' => $result['metrics']],
            ]);
        } elseif ($display === 'chip_suggestions') {
            $this->emit([
                'type' => 'data-chips',
                'data' => ['chips' => $result['chips']],
            ]);
        } elseif ($display === 'handoff') {
            $this->emit([
                'type' => 'data-handoff',
                'data' => ['suggested_prompt' => $result['suggested_prompt'] ?? ''],
            ]);
        } elseif ($display === 'plan_mutated') {
            $this->emit([
                'type' => 'data-plan-changed',
                'data' => [],
            ]);
        }
    }

    private function emit(array $payload): void
    {
        echo 'data: '.json_encode($payload)."\n\n";
        $this->flush();
    }

    private function emitRaw(string $line): void
    {
        echo 'data: '.$line;
        $this->flush();
    }

    private function flush(): void
    {
        if (function_exists('ob_flush')) {
            @ob_flush();
        }
        flush();
    }

    private function humanizeStreamError(Throwable $e): string
    {
        $message = $e->getMessage();

        if ($e instanceof ConnectionException || str_contains($message, 'Connection refused') || str_contains($message, 'Could not resolve host')) {
            return "Couldn't reach the coach. Check your connection and try again.";
        }

        if (str_contains($message, 'rate_limit') || str_contains($message, '429')) {
            return 'The coach is rate-limited right now. Try again in a moment.';
        }

        return 'The coach hit an error. Please try again.';
    }
}
