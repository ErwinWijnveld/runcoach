<?php

namespace Tests\Feature\Coach;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeleteConversationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_deletes_conversation_messages_and_linked_proposals(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        [$convoId, $messageId] = $this->seedConversation($user);

        $proposal = CoachProposal::create([
            'user_id' => $user->id,
            'agent_message_id' => $messageId,
            'type' => ProposalType::CreateSchedule,
            'payload' => ['schedule' => ['weeks' => []]],
            'status' => ProposalStatus::Pending,
        ]);

        $response = $this->deleteJson("/api/v1/coach/conversations/{$convoId}");

        $response->assertNoContent();

        $this->assertDatabaseMissing('agent_conversations', ['id' => $convoId]);
        $this->assertDatabaseMissing('agent_conversation_messages', ['conversation_id' => $convoId]);
        $this->assertDatabaseMissing('coach_proposals', ['id' => $proposal->id]);
    }

    public function test_returns_404_when_conversation_belongs_to_another_user(): void
    {
        $owner = User::factory()->create();
        [$convoId] = $this->seedConversation($owner);

        $intruder = User::factory()->create();
        Sanctum::actingAs($intruder);

        $this->deleteJson("/api/v1/coach/conversations/{$convoId}")
            ->assertNotFound();

        $this->assertDatabaseHas('agent_conversations', ['id' => $convoId]);
    }

    /**
     * @return array{0: string, 1: string}
     */
    private function seedConversation(User $user): array
    {
        $now = now();
        $convoId = (string) Str::uuid();
        $messageId = (string) Str::uuid();

        DB::table('agent_conversations')->insert([
            'id' => $convoId,
            'user_id' => $user->id,
            'title' => 'Chat to delete',
            'context' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('agent_conversation_messages')->insert([
            'id' => $messageId,
            'conversation_id' => $convoId,
            'user_id' => $user->id,
            'agent' => 'run-coach',
            'role' => 'assistant',
            'content' => 'hi',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '{}',
            'meta' => '{}',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return [$convoId, $messageId];
    }
}
