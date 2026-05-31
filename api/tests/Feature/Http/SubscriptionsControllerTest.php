<?php

namespace Tests\Feature\Http;

use App\Models\User;
use App\Services\RevenueCat\RevenueCatRestClient;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class SubscriptionsControllerTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function auth(): array
    {
        // Default to non-pro so sync tests start from a clean slate; specific
        // tests below override pro fields explicitly when needed.
        $user = User::factory()->nonPro()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer {$token}"]];
    }

    public function test_unauthenticated_request_fails(): void
    {
        $this->postJson('/api/v1/subscriptions/sync')->assertStatus(401);
    }

    public function test_active_entitlement_populates_pro_state(): void
    {
        [$user, $headers] = $this->auth();
        $expiresAt = now()->addYear();

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')
            ->once()
            ->with((string) $user->id)
            ->andReturn([
                'pro' => [
                    'lookup_key' => 'pro',
                    'product_identifier' => 'runcoach_pro_yearly',
                    'expires_date_ms' => $expiresAt->getTimestampMs(),
                    'store' => 'APP_STORE',
                    'period_type' => 'NORMAL',
                    'environment' => 'PRODUCTION',
                ],
            ]);
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => true, 'product_id' => 'runcoach_pro_yearly']);

        $user->refresh();
        $this->assertTrue($user->isPro());
        $this->assertSame('runcoach_pro_yearly', $user->pro_product_id);
        $this->assertDatabaseHas('subscriptions', [
            'user_id' => $user->id,
            'product_id' => 'runcoach_pro_yearly',
            'status' => 'active',
        ]);
    }

    public function test_missing_entitlement_clears_expired_state(): void
    {
        [$user, $headers] = $this->auth();
        $user->update([
            'pro_active_until' => now()->subDay(),
            'pro_product_id' => 'runcoach_pro_monthly',
        ]);

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')->once()->andReturn([]);
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => false, 'product_id' => null]);

        $user->refresh();
        $this->assertNull($user->pro_active_until);
        $this->assertNull($user->pro_product_id);
    }

    public function test_missing_entitlement_preserves_future_state(): void
    {
        [$user, $headers] = $this->auth();
        $futureUntil = now()->addMonths(2);
        $user->update([
            'pro_active_until' => $futureUntil,
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')->once()->andReturn([]);
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [], $headers);

        $response->assertOk();
        // Webhook may still be in flight; we don't yank future state.
        $user->refresh();
        $this->assertTrue($user->isPro());
        $this->assertSame('runcoach_pro_yearly', $user->pro_product_id);
    }

    public function test_rest_failure_returns_local_state(): void
    {
        [$user, $headers] = $this->auth();
        $futureUntil = now()->addMonth();
        $user->update([
            'pro_active_until' => $futureUntil,
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')->once()->andThrow(new RuntimeException('boom'));
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => true, 'product_id' => 'runcoach_pro_yearly']);
        $user->refresh();
        $this->assertTrue($user->isPro());
    }

    public function test_local_env_trusts_client_claim_when_rest_fails(): void
    {
        // Test Store dev path: RC REST can't verify, but the client's
        // CustomerInfo says it's pro → in local env we grant the entitlement.
        $this->app['env'] = 'local';

        [$user, $headers] = $this->auth();

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')->once()->andThrow(new RuntimeException('401'));
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [
            'client_entitlement' => [
                'active' => true,
                'product_id' => 'runcoach_pro_yearly',
                'expires_at' => now()->addYear()->toIso8601String(),
            ],
        ], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => true]);
        $user->refresh();
        $this->assertTrue($user->isPro());
        $this->assertDatabaseHas('subscriptions', [
            'user_id' => $user->id,
            'store' => 'test_store',
        ]);
    }

    public function test_production_env_ignores_client_claim_when_rest_fails(): void
    {
        // Same claim, but in production we NEVER trust the client — RC REST is
        // the only source. Failure → local state unchanged (not pro).
        $this->app['env'] = 'production';

        [$user, $headers] = $this->auth();

        $mock = Mockery::mock(RevenueCatRestClient::class);
        $mock->shouldReceive('getActiveEntitlements')->once()->andThrow(new RuntimeException('boom'));
        $this->app->instance(RevenueCatRestClient::class, $mock);

        $response = $this->postJson('/api/v1/subscriptions/sync', [
            'client_entitlement' => [
                'active' => true,
                'product_id' => 'runcoach_pro_yearly',
                'expires_at' => now()->addYear()->toIso8601String(),
            ],
        ], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => false]);
        $user->refresh();
        $this->assertFalse($user->isPro());
        $this->assertDatabaseMissing('subscriptions', ['user_id' => $user->id]);
    }

    public function test_dev_activate_grants_in_local_env(): void
    {
        $this->app['env'] = 'local';
        [$user, $headers] = $this->auth();

        $response = $this->postJson('/api/v1/subscriptions/dev-activate', [], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => true]);
        $user->refresh();
        $this->assertTrue($user->isPro());
        $this->assertDatabaseHas('subscriptions', [
            'user_id' => $user->id,
            'store' => 'test_store',
        ]);
    }

    public function test_dev_deactivate_revokes_in_local_env(): void
    {
        $this->app['env'] = 'local';
        $user = User::factory()->create([
            'pro_active_until' => now()->addYear(),
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);
        $token = $user->createToken('api')->plainTextToken;
        $headers = ['Authorization' => "Bearer {$token}"];

        $response = $this->postJson('/api/v1/subscriptions/dev-deactivate', [], $headers);

        $response->assertOk();
        $response->assertJson(['is_pro' => false]);
        $user->refresh();
        $this->assertFalse($user->isPro());
    }

    public function test_dev_endpoints_404_outside_local_env(): void
    {
        $this->app['env'] = 'production';
        [, $headers] = $this->auth();

        $this->postJson('/api/v1/subscriptions/dev-activate', [], $headers)
            ->assertNotFound();
        $this->postJson('/api/v1/subscriptions/dev-deactivate', [], $headers)
            ->assertNotFound();
    }
}
