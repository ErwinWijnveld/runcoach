<?php

namespace Tests\Feature\Middleware;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RequireProEntitlementTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function auth(?User $user = null): array
    {
        $user ??= User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer {$token}"]];
    }

    public function test_expired_user_blocked_from_coach_chat(): void
    {
        $user = User::factory()->nonPro()->create();
        [, $headers] = $this->auth($user);

        $response = $this->getJson('/api/v1/coach/conversations', $headers);

        $response->assertStatus(402);
        $response->assertJsonFragment(['error' => 'pro_required']);
    }

    public function test_pro_user_passes(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addMonth(),
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);
        [, $headers] = $this->auth($user);

        $response = $this->getJson('/api/v1/coach/conversations', $headers);

        // Endpoint exists and returns 200 with empty list for new pro users.
        $response->assertOk();
    }

    public function test_grace_window_user_passes(): void
    {
        // Subscription expires_at was earlier today, but 24h grace was baked
        // into pro_active_until — they should still be Pro.
        $user = User::factory()->create([
            'pro_active_until' => now()->addHours(6),
            'pro_product_id' => 'runcoach_pro_monthly',
        ]);
        [, $headers] = $this->auth($user);

        $this->getJson('/api/v1/coach/conversations', $headers)->assertOk();
    }

    public function test_past_pro_active_until_blocks(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->subDay(),
            'pro_product_id' => 'runcoach_pro_monthly',
        ]);
        [, $headers] = $this->auth($user);

        $this->getJson('/api/v1/coach/conversations', $headers)->assertStatus(402);
    }
}
