<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingBranchTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_race_branch_appends_user_message_and_race_prompt(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $convoId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode(['onboarding_step' => 'awaiting_branch']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Race coming up!',
            'chip_value' => 'race',
        ]);

        $response->assertOk()->assertJsonStructure(['messages']);

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $convoId)
            ->orderBy('created_at')
            ->get();

        $this->assertCount(2, $messages);
        $this->assertEquals('user', $messages[0]->role);
        $this->assertEquals('Race coming up!', $messages[0]->content);
        $this->assertEquals('assistant', $messages[1]->role);
        $this->assertStringContainsString("let's get you going", $messages[1]->content);

        $updated = DB::table('agent_conversations')->where('id', $convoId)->first();
        $meta = json_decode($updated->meta, true);
        $this->assertEquals('awaiting_race_details', $meta['onboarding_step']);
    }
}
