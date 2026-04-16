<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetActivityDetails;
use App\Models\StravaToken;
use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class GetActivityDetailsTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function callTool(User $user, int $activityId): array
    {
        $tool = new GetActivityDetails($user, app(StravaSyncService::class));
        $request = new Request(['activity_id' => $activityId]);

        return json_decode($tool->handle($request), true);
    }

    public function test_returns_error_when_user_has_no_strava_token(): void
    {
        $user = User::factory()->create();

        $result = $this->callTool($user, 12345);

        $this->assertArrayHasKey('message', $result);
        $this->assertStringContainsString('No Strava connection', $result['message']);
    }

    public function test_returns_summary_and_splits_for_a_run(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/99999' => Http::response([
                'id' => 99999,
                'name' => 'Morning Run',
                'type' => 'Run',
                'start_date' => '2026-04-15T07:00:00Z',
                'distance' => 5025.4,
                'moving_time' => 1520,
                'average_heartrate' => 148.0,
                'max_heartrate' => 172.0,
                'total_elevation_gain' => 42.1,
                'has_heartrate' => true,
                'average_cadence' => 85.0,
                'splits_metric' => [
                    [
                        'split' => 1,
                        'distance' => 1006.5,
                        'moving_time' => 310,
                        'elevation_difference' => 5.0,
                        'average_heartrate' => 140.0,
                        'pace_zone' => 2,
                    ],
                    [
                        'split' => 2,
                        'distance' => 1004.2,
                        'moving_time' => 295,
                        'elevation_difference' => -2.0,
                        'average_heartrate' => 152.0,
                        'pace_zone' => 3,
                    ],
                ],
                'laps' => [],
            ], 200),
        ]);

        $result = $this->callTool($user, 99999);

        $this->assertSame(99999, $result['summary']['id']);
        $this->assertSame('Morning Run', $result['summary']['name']);
        $this->assertSame(148, $result['summary']['avg_heart_rate']);
        $this->assertSame(172, $result['summary']['max_heart_rate']);

        $this->assertCount(2, $result['splits_metric']);
        $this->assertSame(1, $result['splits_metric'][0]['split']);
        $this->assertSame('5:08/km', $result['splits_metric'][0]['pace']);
        $this->assertSame(140, $result['splits_metric'][0]['average_heart_rate']);
        $this->assertSame('4:54/km', $result['splits_metric'][1]['pace']);
    }

    public function test_formats_laps_when_present(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/77777' => Http::response([
                'id' => 77777,
                'name' => 'Intervals',
                'type' => 'Run',
                'start_date' => '2026-04-10T17:00:00Z',
                'distance' => 8000,
                'moving_time' => 2400,
                'splits_metric' => [],
                'laps' => [
                    [
                        'lap_index' => 1,
                        'name' => 'Warmup',
                        'distance' => 2000.0,
                        'moving_time' => 720,
                        'average_heartrate' => 130.0,
                        'max_heartrate' => 145.0,
                        'total_elevation_gain' => 5.0,
                    ],
                    [
                        'lap_index' => 2,
                        'name' => '400m repeat',
                        'distance' => 400.0,
                        'moving_time' => 84,
                        'average_heartrate' => 175.0,
                        'max_heartrate' => 182.0,
                        'total_elevation_gain' => 0.0,
                    ],
                ],
            ], 200),
        ]);

        $result = $this->callTool($user, 77777);

        $this->assertCount(2, $result['laps']);
        $this->assertSame(1, $result['laps'][0]['lap']);
        $this->assertSame('Warmup', $result['laps'][0]['name']);
        $this->assertSame('400m repeat', $result['laps'][1]['name']);
        $this->assertSame(175, $result['laps'][1]['average_heart_rate']);
    }

    public function test_handles_missing_splits_and_laps_gracefully(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/55555' => Http::response([
                'id' => 55555,
                'name' => 'Short walk',
                'type' => 'Run',
                'start_date' => '2026-04-01T07:00:00Z',
                'distance' => 800.0,
                'moving_time' => 360,
            ], 200),
        ]);

        $result = $this->callTool($user, 55555);

        $this->assertSame([], $result['splits_metric']);
        $this->assertSame([], $result['laps']);
        $this->assertSame('Short walk', $result['summary']['name']);
    }

    public function test_returns_error_string_when_strava_fails(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/*' => Http::response(['message' => 'Not Found'], 404),
        ]);

        $result = $this->callTool($user, 42);

        $this->assertArrayHasKey('error', $result);
    }
}
