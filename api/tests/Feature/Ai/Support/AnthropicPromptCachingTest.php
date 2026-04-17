<?php

namespace Tests\Feature\Ai\Support;

use App\Ai\Support\AnthropicPromptCaching;
use GuzzleHttp\Psr7\Request;
use Tests\TestCase;

class AnthropicPromptCachingTest extends TestCase
{
    public function test_adds_ephemeral_cache_control_to_last_tool(): void
    {
        $body = json_encode([
            'model' => 'claude-sonnet-4-6',
            'system' => 'You are an assistant.',
            'tools' => [
                ['name' => 'first', 'input_schema' => ['type' => 'object']],
                ['name' => 'second', 'input_schema' => ['type' => 'object']],
            ],
            'messages' => [['role' => 'user', 'content' => [['type' => 'text', 'text' => 'hi']]]],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);
        $result = (new AnthropicPromptCaching)($request);

        $newBody = (string) $result->getBody();
        $this->assertStringContainsString('"cache_control":{"type":"ephemeral"}', $newBody);

        $decoded = json_decode($newBody, true);
        $this->assertArrayNotHasKey('cache_control', $decoded['tools'][0]);
        $this->assertSame('ephemeral', $decoded['tools'][1]['cache_control']['type']);
    }

    public function test_skips_non_anthropic_requests(): void
    {
        $request = new Request('POST', 'https://api.openai.com/v1/chat', [], 'payload');
        $result = (new AnthropicPromptCaching)($request);
        $this->assertSame('payload', (string) $result->getBody());
    }

    public function test_noop_when_no_tools(): void
    {
        $body = json_encode(['messages' => [['role' => 'user', 'content' => 'hi']]]);
        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);
        $result = (new AnthropicPromptCaching)($request);
        $this->assertSame($request, $result);
    }

    public function test_noop_when_last_tool_already_cached(): void
    {
        $body = json_encode([
            'tools' => [
                ['name' => 'only', 'input_schema' => ['type' => 'object'], 'cache_control' => ['type' => 'ephemeral']],
            ],
            'messages' => [['role' => 'user', 'content' => 'hi']],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);
        $result = (new AnthropicPromptCaching)($request);

        $this->assertSame($request, $result);
    }
}
