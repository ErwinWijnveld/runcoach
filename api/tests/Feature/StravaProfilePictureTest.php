<?php

namespace Tests\Feature;

use App\Services\StravaSyncService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class StravaProfilePictureTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_medium_url_is_stored_on_user(): void
    {
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999001,
                'firstname' => 'Eliud',
                'lastname' => 'Kipchoge',
                'email' => 'eliud@example.com',
                'profile_medium' => 'https://dgalywyr863hv.cloudfront.net/pictures/athletes/medium.jpg',
                'profile' => 'https://dgalywyr863hv.cloudfront.net/pictures/athletes/large.jpg',
            ],
        ]);

        $this->assertSame(
            'https://dgalywyr863hv.cloudfront.net/pictures/athletes/medium.jpg',
            $user->fresh()->strava_profile_url,
        );
    }

    public function test_falls_back_to_profile_when_medium_missing(): void
    {
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999002,
                'firstname' => 'A',
                'lastname' => 'B',
                'email' => 'a@b.com',
                'profile' => 'https://example.com/fallback.jpg',
            ],
        ]);

        $this->assertSame('https://example.com/fallback.jpg', $user->fresh()->strava_profile_url);
    }

    public function test_null_when_strava_returns_placeholder(): void
    {
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999003,
                'firstname' => 'A',
                'lastname' => 'B',
                'email' => 'c@d.com',
                'profile_medium' => 'avatar/athlete/medium.png',
                'profile' => 'avatar/athlete/large.png',
            ],
        ]);

        $this->assertNull($user->fresh()->strava_profile_url);
    }
}
