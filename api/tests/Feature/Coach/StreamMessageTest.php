<?php

namespace Tests\Feature\Coach;

use App\Ai\Agents\RunCoachAgent;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class StreamMessageTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_streams_text_deltas_as_sse(): void
    {
        RunCoachAgent::fake(['Hello there friend.']);

        [$user, $headers] = $this->authUser();

        $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'Test'], $headers);
        $conversationId = $created->json('data.id');

        $response = $this->call(
            'POST',
            "/api/v1/coach/conversations/{$conversationId}/messages",
            ['content' => 'Hi'],
            [],
            [],
            $this->transformHeadersToServerVars($headers),
        );

        $response->assertOk();
        $this->assertStringContainsString(
            'text/event-stream',
            $response->headers->get('Content-Type'),
        );

        $body = $response->streamedContent();

        $this->assertStringContainsString('"type":"text-delta"', $body);
        $this->assertStringContainsString("data: [DONE]\n\n", $body);

        $this->assertDatabaseHas('agent_conversation_messages', [
            'conversation_id' => $conversationId,
            'role' => 'assistant',
            'content' => 'Hello there friend.',
        ]);
    }
}
