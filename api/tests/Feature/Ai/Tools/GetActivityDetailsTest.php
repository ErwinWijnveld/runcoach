<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetActivityDetails;
use App\Models\StravaToken;
use App\Models\User;
use App\Services\StravaStreamSplits;
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
        $tool = new GetActivityDetails(
            $user,
            app(StravaSyncService::class),
            app(StravaStreamSplits::class),
        );
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

    public function test_returns_summary_and_fine_grained_splits_for_a_run(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/99999/streams*' => Http::response([
                'time' => ['data' => [0, 5, 10, 15, 20, 25, 30, 35, 40]],
                'distance' => ['data' => [0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0, 105.0, 120.0]],
                'heartrate' => ['data' => [140, 142, 145, 148, 150, 152, 155, 157, 158]],
            ], 200),
            'strava.com/api/v3/activities/99999' => Http::response([
                'id' => 99999,
                'name' => 'Morning Run',
                'type' => 'Run',
                'start_date' => '2026-04-15T07:00:00Z',
                'distance' => 5025.4,                // <10 km → 50m buckets
                'moving_time' => 1520,
                'average_heartrate' => 148.0,
                'max_heartrate' => 172.0,
                'total_elevation_gain' => 42.1,
                'has_heartrate' => true,
                'average_cadence' => 85.0,
                'laps' => [],
            ], 200),
        ]);

        $result = $this->callTool($user, 99999);

        $this->assertSame(99999, $result['summary']['id']);
        $this->assertSame('Morning Run', $result['summary']['name']);
        $this->assertSame(148, $result['summary']['avg_heart_rate']);

        // Fine-grained splits — 3 × 50m buckets from the streams above.
        $this->assertGreaterThanOrEqual(2, count($result['splits']));
        $this->assertArrayHasKey('distance_m', $result['splits'][0]);
        $this->assertArrayHasKey('pace_seconds_per_km', $result['splits'][0]);
        $this->assertArrayHasKey('average_heart_rate', $result['splits'][0]);
    }

    public function test_formats_laps_when_present(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/activities/77777/streams*' => Http::response([], 200),
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
            'strava.com/api/v3/activities/55555/streams*' => Http::response([], 200),
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

        $this->assertSame([], $result['splits']);
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
