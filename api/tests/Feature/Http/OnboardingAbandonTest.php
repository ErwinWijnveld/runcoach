<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingAbandonTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_not_sure_yet_chip_marks_onboarding_complete_without_goal(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);
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

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Not sure yet',
            'chip_value' => 'skip',
        ])->assertOk();

        $user->refresh();
        $this->assertTrue((bool) $user->has_completed_onboarding);

        $updated = DB::table('agent_conversations')->where('id', $convoId)->first();
        $meta = json_decode($updated->meta, true);
        $this->assertEquals('abandoned', $meta['onboarding_step']);

        $last = DB::table('agent_conversation_messages')
            ->where('conversation_id', $convoId)
            ->where('role', 'assistant')
            ->orderByDesc('created_at')
            ->first();
        $this->assertStringContainsString('No stress', $last->content);
    }
}
