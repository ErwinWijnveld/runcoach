<?php

namespace App\Ai\Support;

use GuzzleHttp\Psr7\Utils;
use Psr\Http\Message\RequestInterface;
use stdClass;

/**
 * Adds Anthropic prompt-cache breakpoints to outgoing Messages API requests.
 *
 * Placing `cache_control: ephemeral` on the last tool tells Anthropic to cache
 * everything up to that point (system + all tool definitions). Subsequent
 * requests within ~5 minutes with an identical prefix hit the cache and read
 * those input tokens at ~10% of the normal price.
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

        if (! isset($data->tools) || ! is_array($data->tools) || $data->tools === []) {
            return $request;
        }

        $lastTool = $data->tools[count($data->tools) - 1];

        if (! $lastTool instanceof stdClass || isset($lastTool->cache_control)) {
            return $request;
        }

        $lastTool->cache_control = (object) ['type' => 'ephemeral'];

        return $request
            ->withBody(Utils::streamFor(json_encode($data)))
            ->withoutHeader('Content-Length');
    }
}
