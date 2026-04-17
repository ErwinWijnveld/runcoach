<?php

namespace App\Ai\Support;

use GuzzleHttp\Psr7\Utils;
use Psr\Http\Message\RequestInterface;
use stdClass;

/**
 * Works around a laravel/ai v0.5.1 bug where tool_use.input is serialized as
 * `[]` (JSON array) instead of `{}` (JSON object) for tools with no arguments
 * when messages are reloaded from the conversation store. PHP can't distinguish
 * an empty JSON object from an empty JSON array once decoded with assoc=true,
 * so the round-trip through DatabaseConversationStore collapses `{}` to `[]`,
 * and Anthropic rejects the follow-up request with a 400.
 */
class AnthropicToolInputSanitizer
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
        if (! $data instanceof stdClass || ! isset($data->messages) || ! is_array($data->messages)) {
            return $request;
        }

        $changed = false;
        foreach ($data->messages as $message) {
            if (! $message instanceof stdClass || ($message->role ?? '') !== 'assistant') {
                continue;
            }
            if (! is_array($message->content ?? null)) {
                continue;
            }
            foreach ($message->content as $block) {
                if ($block instanceof stdClass
                    && ($block->type ?? '') === 'tool_use'
                    && is_array($block->input ?? null)
                    && empty($block->input)) {
                    $block->input = new stdClass;
                    $changed = true;
                }
            }
        }

        if (! $changed) {
            return $request;
        }

        return $request
            ->withBody(Utils::streamFor(json_encode($data)))
            ->withoutHeader('Content-Length');
    }
}
