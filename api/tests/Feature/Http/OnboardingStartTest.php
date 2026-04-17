<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingStartTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_creates_onboarding_conversation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/onboarding/start');

        $response->assertOk()->assertJsonStructure(['conversation_id']);

        $this->assertEquals(
            1,
            DB::table('agent_conversations')
                ->where('user_id', $user->id)
                ->where('context', 'onboarding')
                ->count(),
        );
    }

    public function test_idempotent(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $first = $this->postJson('/api/v1/onboarding/start')->assertOk();
        $second = $this->postJson('/api/v1/onboarding/start')->assertOk();

        $this->assertEquals(
            $first->json('conversation_id'),
            $second->json('conversation_id'),
        );
    }
}
