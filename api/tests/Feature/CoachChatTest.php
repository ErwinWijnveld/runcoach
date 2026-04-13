<?php

namespace Tests\Feature;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class CoachChatTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_create_conversation(): void
    {
        RunCoachAgent::fake(['Hello! I\'m your running coach.']);

        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Training Chat',
        ], $headers);

        $response->assertCreated();
        $response->assertJsonStructure(['data' => ['id', 'title']]);
    }

    public function test_send_message(): void
    {
        RunCoachAgent::fake([
            'Hello! I\'m your running coach.',
            'Based on your recent runs, you\'re doing great!',
        ]);

        [$user, $headers] = $this->authUser();

        // Create conversation first
        $createResponse = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Test Chat',
        ], $headers);

        $conversationId = $createResponse->json('data.id');

        // Send follow-up message
        $response = $this->postJson("/api/v1/coach/conversations/{$conversationId}/messages", [
            'content' => 'How is my training going?',
        ], $headers);

        $response->assertOk();
        $response->assertJsonStructure(['data' => ['message' => ['role', 'content']]]);
    }

    public function test_accept_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'payload' => [
                'race_name' => 'Test Race',
                'distance' => 'half_marathon',
                'race_date' => now()->addMonths(3)->toDateString(),
                'schedule' => ['weeks' => []],
            ],
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/accept", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Accepted, $proposal->fresh()->status);
    }

    public function test_reject_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/reject", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Rejected, $proposal->fresh()->status);
    }
}
