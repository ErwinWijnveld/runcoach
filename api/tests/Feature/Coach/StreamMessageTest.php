<?php

namespace Tests\Feature\Coach;

use App\Ai\Agents\RunCoachAgent;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
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

    public function test_emits_data_proposal_event_when_proposal_detected(): void
    {
        RunCoachAgent::fake(['Schedule created.']);

        [$user, $headers] = $this->authUser();

        $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'T'], $headers);
        $conversationId = $created->json('data.id');

        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'agent_message_id' => Str::uuid()->toString(),
        ]);

        $this->mock(ProposalService::class, function ($mock) use ($proposal) {
            $mock->shouldReceive('detectProposalFromConversation')
                ->once()
                ->andReturn($proposal);
        });

        $response = $this->call(
            'POST',
            "/api/v1/coach/conversations/{$conversationId}/messages",
            ['content' => 'Create a plan'],
            [],
            [],
            $this->transformHeadersToServerVars($headers),
        );

        $response->assertOk();
        $body = $response->streamedContent();

        $this->assertStringContainsString('"type":"data-proposal"', $body);
        $this->assertStringContainsString('"id":'.$proposal->id, $body);
    }

    public function test_does_not_emit_data_proposal_when_no_proposal_detected(): void
    {
        RunCoachAgent::fake(['Just chatting.']);

        [$user, $headers] = $this->authUser();

        $created = $this->postJson('/api/v1/coach/conversations', ['title' => 'T'], $headers);
        $conversationId = $created->json('data.id');

        $this->mock(ProposalService::class, function ($mock) {
            $mock->shouldReceive('detectProposalFromConversation')
                ->once()
                ->andReturn(null);
        });

        $response = $this->call(
            'POST',
            "/api/v1/coach/conversations/{$conversationId}/messages",
            ['content' => 'Hello'],
            [],
            [],
            $this->transformHeadersToServerVars($headers),
        );

        $response->assertOk();
        $body = $response->streamedContent();

        $this->assertStringNotContainsString('"type":"data-proposal"', $body);
        $this->assertStringContainsString("data: [DONE]\n\n", $body);
    }
}
