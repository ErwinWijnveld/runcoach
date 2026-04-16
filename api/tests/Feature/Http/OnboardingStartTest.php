<?php

namespace Tests\Feature\Http;

use App\Jobs\AnalyzeRunningProfileJob;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingStartTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_start_creates_onboarding_conversation_and_dispatches_job(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/onboarding/start');

        $response->assertOk()
            ->assertJsonStructure(['conversation_id', 'messages'])
            ->assertJsonCount(1, 'messages')
            ->assertJsonPath('messages.0.meta.message_type', 'loading_card');

        $conversation = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();
        $this->assertNotNull($conversation);

        $meta = json_decode($conversation->meta, true);
        $this->assertEquals('pending_analysis', $meta['onboarding_step']);

        Queue::assertPushed(AnalyzeRunningProfileJob::class);
    }

    public function test_start_is_idempotent(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $first = $this->postJson('/api/v1/onboarding/start')->assertOk();
        $second = $this->postJson('/api/v1/onboarding/start')->assertOk();

        $this->assertEquals(
            $first->json('conversation_id'),
            $second->json('conversation_id'),
        );
        $this->assertEquals(
            1,
            DB::table('agent_conversations')
                ->where('user_id', $user->id)
                ->where('context', 'onboarding')
                ->count(),
        );
    }
}
