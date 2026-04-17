<?php

namespace Tests\Feature\Ai\Support;

use App\Ai\Support\AnthropicToolInputSanitizer;
use GuzzleHttp\Psr7\Request;
use Tests\TestCase;

class AnthropicToolInputSanitizerTest extends TestCase
{
    public function test_rewrites_empty_tool_use_input_array_to_object(): void
    {
        $body = json_encode([
            'model' => 'claude-sonnet-4-6',
            'messages' => [
                ['role' => 'user', 'content' => [['type' => 'text', 'text' => 'hi']]],
                ['role' => 'assistant', 'content' => [
                    ['type' => 'tool_use', 'id' => 'toolu_1', 'name' => 'GetRunningProfile', 'input' => []],
                ]],
            ],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);

        $result = (new AnthropicToolInputSanitizer)($request);

        $decoded = json_decode((string) $result->getBody(), true);
        $this->assertSame([], $decoded['messages'][1]['content'][0]['input'],
            'Decoded PHP still shows [] because assoc=true hides the distinction');

        $this->assertStringContainsString('"input":{}', (string) $result->getBody());
    }

    public function test_preserves_non_empty_tool_use_input(): void
    {
        $body = json_encode([
            'messages' => [
                ['role' => 'assistant', 'content' => [
                    ['type' => 'tool_use', 'id' => 'toolu_1', 'name' => 'PresentRunningStats', 'input' => ['weekly_avg_km' => 8.6]],
                ]],
            ],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);

        $result = (new AnthropicToolInputSanitizer)($request);

        $this->assertStringContainsString('"input":{"weekly_avg_km":8.6}', (string) $result->getBody());
    }

    public function test_does_not_touch_non_anthropic_requests(): void
    {
        $body = 'original body';
        $request = new Request('POST', 'https://api.openai.com/v1/chat', [], $body);

        $result = (new AnthropicToolInputSanitizer)($request);

        $this->assertSame('original body', (string) $result->getBody());
    }

    public function test_does_not_rewrite_when_no_empty_tool_input_present(): void
    {
        $body = json_encode([
            'messages' => [
                ['role' => 'user', 'content' => [['type' => 'text', 'text' => 'hello']]],
            ],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);

        $result = (new AnthropicToolInputSanitizer)($request);

        $this->assertSame($request, $result, 'Returns original request unchanged when no fix needed');
    }

    public function test_preserves_empty_tool_schema_properties(): void
    {
        // tools[i].input_schema.properties should stay as `{}` (empty object),
        // even when messages also need rewriting. The middleware must not
        // round-trip through assoc arrays, which would collapse `{}` to `[]`.
        $body = json_encode([
            'messages' => [
                ['role' => 'assistant', 'content' => [
                    ['type' => 'tool_use', 'id' => 'toolu_1', 'name' => 'NoArgs', 'input' => []],
                ]],
            ],
            'tools' => [
                [
                    'name' => 'NoArgs',
                    'description' => 'has no params',
                    'input_schema' => ['type' => 'object', 'properties' => (object) []],
                ],
            ],
        ]);

        $request = new Request('POST', 'https://api.anthropic.com/v1/messages', [], $body);

        $result = (new AnthropicToolInputSanitizer)($request);

        $newBody = (string) $result->getBody();
        $this->assertStringContainsString('"input":{}', $newBody);
        $this->assertStringContainsString('"properties":{}', $newBody);
    }
}
