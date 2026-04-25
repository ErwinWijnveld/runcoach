<?php

namespace App\Ai\Support;

use GuzzleHttp\Psr7\Utils;
use Psr\Http\Message\RequestInterface;
use stdClass;

/**
 * Adds Anthropic prompt-cache breakpoints to outgoing Messages API requests.
 *
 * Two breakpoints are attached per request:
 *  1. `cache_control: ephemeral` on the last tool — caches `system` + all
 *     tool definitions (a static prefix that rarely changes).
 *  2. `cache_control: ephemeral` on the last content block of the last
 *     assistant message — caches the conversation history so the next
 *     turn only pays full input price for the new user message.
 *
 * Subsequent requests within ~5 minutes with an identical prefix hit the
 * cache and read those input tokens at ~10% of the normal price.
 *
 * See https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
 */
class AnthropicPromptCaching
{
    public function __invoke(RequestInterface $request): RequestInterface
    {
        if (! str_contains((string) $request->getUri(), 'api.anthropic.com')) {
            return $request;
        }

        $body = (string) $request->getBody();
        if ($body === '') {
            return $request;
        }

        $data = json_decode($body);
        if (! $data instanceof stdClass) {
            return $request;
        }

        $toolsChanged = $this->cacheLastTool($data);
        $messagesChanged = $this->cacheLastAssistantMessage($data);

        if (! $toolsChanged && ! $messagesChanged) {
            return $request;
        }

        return $request
            ->withBody(Utils::streamFor(json_encode($data)))
            ->withoutHeader('Content-Length');
    }

    /**
     * Attach cache_control to the last tool definition. Caches
     * `system` + all `tools` as a single static prefix that survives
     * across turns for ~5 minutes.
     */
    private function cacheLastTool(stdClass $data): bool
    {
        if (! isset($data->tools) || ! is_array($data->tools) || $data->tools === []) {
            return false;
        }

        $lastTool = $data->tools[count($data->tools) - 1];

        if (! $lastTool instanceof stdClass || isset($lastTool->cache_control)) {
            return false;
        }

        $lastTool->cache_control = (object) ['type' => 'ephemeral'];

        return true;
    }

    /**
     * Attach cache_control to the last content block of the last
     * assistant message. Caches the conversation history up to (and
     * including) that assistant turn so the next user message pays full
     * input price only on the new content, not the whole history.
     */
    private function cacheLastAssistantMessage(stdClass $data): bool
    {
        if (! isset($data->messages) || ! is_array($data->messages) || $data->messages === []) {
            return false;
        }

        $lastAssistantIndex = null;
        foreach ($data->messages as $i => $message) {
            if ($message instanceof stdClass && ($message->role ?? null) === 'assistant') {
                $lastAssistantIndex = $i;
            }
        }

        if ($lastAssistantIndex === null) {
            return false;
        }

        return $this->attachCacheControlToLastContentBlock($data->messages[$lastAssistantIndex]);
    }

    /**
     * Coerce the message's content into an array of content blocks and
     * attach cache_control: ephemeral to the last block. Returns true
     * when a change was made, false when the block already had cache
     * control (idempotent) or the content shape was unexpected.
     */
    private function attachCacheControlToLastContentBlock(stdClass $message): bool
    {
        $content = $message->content ?? null;

        if (is_string($content)) {
            $message->content = [
                (object) ['type' => 'text', 'text' => $content],
            ];
            $content = $message->content;
        }

        if (! is_array($content) || $content === []) {
            return false;
        }

        $last = $content[count($content) - 1];

        if (! $last instanceof stdClass || isset($last->cache_control)) {
            return false;
        }

        $last->cache_control = (object) ['type' => 'ephemeral'];

        return true;
    }
}
