<?php

namespace Tests\Feature\Http;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class DeviceTokenControllerTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authHeaders(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('api')->plainTextToken];
    }

    public function test_post_devices_creates_token_row(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/v1/devices', [
            'token' => str_repeat('a', 64),
            'platform' => 'ios',
            'app_version' => '1.0.0+7',
        ], $this->authHeaders($user))->assertAccepted();

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $user->id,
            'token' => str_repeat('a', 64),
            'platform' => 'ios',
            'app_version' => '1.0.0+7',
        ]);
    }

    public function test_post_devices_is_idempotent_per_user_and_token(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);
        $token = str_repeat('b', 64);

        $this->postJson('/api/v1/devices', ['token' => $token, 'platform' => 'ios'], $headers)
            ->assertAccepted();

        $this->travel(2)->minutes();

        $this->postJson('/api/v1/devices', ['token' => $token, 'platform' => 'ios'], $headers)
            ->assertAccepted();

        $this->assertSame(1, DeviceToken::where('user_id', $user->id)->count());
        $row = DeviceToken::where('user_id', $user->id)->first();
        $this->assertTrue($row->last_seen_at->gt(now()->subMinute()));
    }

    public function test_delete_devices_removes_only_that_users_token(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $shared = str_repeat('c', 64);

        DeviceToken::factory()->create(['user_id' => $userA->id, 'token' => $shared]);
        DeviceToken::factory()->create(['user_id' => $userB->id, 'token' => $shared]);

        $this->deleteJson('/api/v1/devices', ['token' => $shared], $this->authHeaders($userA))
            ->assertNoContent();

        $this->assertDatabaseMissing('device_tokens', ['user_id' => $userA->id, 'token' => $shared]);
        $this->assertDatabaseHas('device_tokens', ['user_id' => $userB->id, 'token' => $shared]);
    }

    public function test_devices_endpoints_require_auth(): void
    {
        $this->postJson('/api/v1/devices', ['token' => str_repeat('a', 64), 'platform' => 'ios'])
            ->assertUnauthorized();

        $this->deleteJson('/api/v1/devices', ['token' => str_repeat('a', 64)])
            ->assertUnauthorized();
    }

    public function test_post_devices_validates_platform(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/v1/devices', [
            'token' => str_repeat('a', 64),
            'platform' => 'windows',
        ], $this->authHeaders($user))->assertUnprocessable();
    }
}
