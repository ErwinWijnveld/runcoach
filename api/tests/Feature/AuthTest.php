<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\Auth\AppleIdentityTokenVerifier;
use App\Services\Auth\InvalidAppleIdentityTokenException;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function fakeAppleVerifier(string $sub, ?string $email = null): void
    {
        $mock = Mockery::mock(AppleIdentityTokenVerifier::class);
        $mock->shouldReceive('verify')->andReturn([
            'sub' => $sub,
            'email' => $email,
            'email_verified' => true,
        ]);

        $this->app->instance(AppleIdentityTokenVerifier::class, $mock);
    }

    public function test_apple_sign_in_creates_user_and_returns_token(): void
    {
        $this->fakeAppleVerifier('apple-sub-001', 'jane@example.com');

        $response = $this->postJson('/api/v1/auth/apple', [
            'identity_token' => 'fake.jwt.value',
            'name' => 'Jane Runner',
        ]);

        $response->assertOk();
        $response->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);
        $this->assertDatabaseHas('users', [
            'apple_sub' => 'apple-sub-001',
            'email' => 'jane@example.com',
            'name' => 'Jane Runner',
        ]);
    }

    public function test_apple_sign_in_returns_existing_user_for_known_sub(): void
    {
        $existing = User::factory()->create([
            'apple_sub' => 'apple-sub-002',
            'name' => 'Returning Runner',
        ]);

        $this->fakeAppleVerifier('apple-sub-002');

        $response = $this->postJson('/api/v1/auth/apple', [
            'identity_token' => 'fake.jwt.value',
        ]);

        $response->assertOk();
        $this->assertSame($existing->id, $response->json('user.id'));
        $this->assertDatabaseCount('users', 1);
    }

    public function test_apple_sign_in_falls_back_to_synthetic_email_when_token_omits_it(): void
    {
        $this->fakeAppleVerifier('apple-sub-003');

        $response = $this->postJson('/api/v1/auth/apple', [
            'identity_token' => 'fake.jwt.value',
        ]);

        $response->assertOk();
        $this->assertDatabaseHas('users', [
            'apple_sub' => 'apple-sub-003',
            'email' => 'apple-sub-003@privaterelay.appleid.com',
        ]);
    }

    public function test_apple_sign_in_rejects_invalid_token(): void
    {
        $mock = Mockery::mock(AppleIdentityTokenVerifier::class);
        $mock->shouldReceive('verify')->andThrow(
            new InvalidAppleIdentityTokenException('Wrong issuer')
        );
        $this->app->instance(AppleIdentityTokenVerifier::class, $mock);

        $this->postJson('/api/v1/auth/apple', [
            'identity_token' => 'bogus.token',
        ])->assertStatus(401);
    }

    public function test_apple_sign_in_requires_identity_token(): void
    {
        $this->postJson('/api/v1/auth/apple', [])
            ->assertStatus(422);
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->postJson('/api/v1/auth/logout', [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
