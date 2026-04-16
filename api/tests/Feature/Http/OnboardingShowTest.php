<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingShowTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function createOnboardingConversation(int $userId): string
    {
        $conversationId = (string) Str::uuid();
        $now = now();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $userId,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode(['onboarding_step' => 'awaiting_branch']),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('agent_conversation_messages')->insert([
            'id' => (string) Str::uuid(),
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => 'Hello there!',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => json_encode(['message_type' => 'text', 'message_payload' => []]),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $conversationId;
    }

    public function test_show_returns_conversation_id_and_messages_with_decoded_meta(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = $this->createOnboardingConversation($user->id);

        $response = $this->getJson("/api/v1/onboarding/conversations/{$convoId}");

        $response->assertOk()
            ->assertJsonStructure(['conversation_id', 'messages'])
            ->assertJsonPath('conversation_id', $convoId);

        $messages = $response->json('messages');
        $this->assertCount(1, $messages);

        // meta should be decoded (array, not a JSON string)
        $this->assertIsArray($messages[0]['meta']);
        $this->assertEquals('text', $messages[0]['meta']['message_type']);
    }

    public function test_show_returns_404_if_conversation_belongs_to_another_user(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();

        $convoId = $this->createOnboardingConversation($owner->id);

        Sanctum::actingAs($other);

        $this->getJson("/api/v1/onboarding/conversations/{$convoId}")
            ->assertNotFound();
    }

    public function test_show_returns_404_if_conversation_is_not_onboarding_context(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $conversationId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Regular chat',
            'context' => null,
            'meta' => json_encode([]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->getJson("/api/v1/onboarding/conversations/{$conversationId}")
            ->assertNotFound();
    }
}
