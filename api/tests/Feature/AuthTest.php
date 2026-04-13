<?php

namespace Tests\Feature;

use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_strava_redirect_returns_authorize_url(): void
    {
        $response = $this->getJson('/api/v1/auth/strava/redirect');

        $response->assertOk();
        $response->assertJsonStructure(['url']);
        $this->assertStringContainsString('strava.com/oauth/authorize', $response->json('url'));
    }

    public function test_strava_callback_creates_user_and_returns_token(): void
    {
        Queue::fake();

        Http::fake([
            'www.strava.com/oauth/token' => Http::response([
                'access_token' => 'fake_access_token',
                'refresh_token' => 'fake_refresh_token',
                'expires_at' => now()->addHours(6)->timestamp,
                'athlete' => [
                    'id' => 12345,
                    'firstname' => 'Test',
                    'lastname' => 'Runner',
                    'email' => 'test@example.com',
                ],
            ]),
        ]);

        $response = $this->getJson('/api/v1/auth/strava/callback?code=test_auth_code');

        $response->assertOk();
        $response->assertJsonStructure(['token', 'user']);

        $this->assertDatabaseHas('users', [
            'strava_athlete_id' => 12345,
            'name' => 'Test Runner',
        ]);
        $this->assertDatabaseCount('strava_tokens', 1);
    }

    public function test_strava_callback_updates_existing_user(): void
    {
        Queue::fake();

        $user = User::factory()->create(['strava_athlete_id' => 12345]);
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'www.strava.com/oauth/token' => Http::response([
                'access_token' => 'new_access_token',
                'refresh_token' => 'new_refresh_token',
                'expires_at' => now()->addHours(6)->timestamp,
                'athlete' => [
                    'id' => 12345,
                    'firstname' => 'Test',
                    'lastname' => 'Runner',
                    'email' => 'test@example.com',
                ],
            ]),
        ]);

        $response = $this->getJson('/api/v1/auth/strava/callback?code=test_auth_code');

        $response->assertOk();
        $this->assertDatabaseCount('users', 1);
        $this->assertDatabaseCount('strava_tokens', 1);
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
