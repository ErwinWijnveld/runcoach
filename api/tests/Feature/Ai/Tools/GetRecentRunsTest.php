<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetRecentRuns;
use App\Models\StravaToken;
use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class GetRecentRunsTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function fakeStravaActivities(array $activities): void
    {
        Http::fake([
            'strava.com/api/v3/athlete/activities*' => Http::response($activities, 200),
        ]);
    }

    private function callTool(User $user, ?int $limit): array
    {
        $tool = new GetRecentRuns($user, app(StravaSyncService::class));
        $request = new Request(['limit' => $limit]);

        return json_decode($tool->handle($request), true);
    }

    public function test_returns_error_message_when_user_has_no_strava_token(): void
    {
        $user = User::factory()->create();

        $result = $this->callTool($user, 5);

        $this->assertArrayHasKey('message', $result);
        $this->assertStringContainsString('No Strava connection', $result['message']);
    }

    public function test_returns_recent_runs_with_aggregates(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $this->fakeStravaActivities([
            [
                'id' => 1001,
                'type' => 'Run',
                'name' => 'Morning Run',
                'distance' => 5000.0,
                'moving_time' => 1500,
                'start_date' => '2026-04-15T07:00:00Z',
                'average_heartrate' => 145,
                'total_elevation_gain' => 20,
            ],
            [
                'id' => 1002,
                'type' => 'Run',
                'name' => 'Evening Run',
                'distance' => 10000.0,
                'moving_time' => 3000,
                'start_date' => '2026-04-14T18:00:00Z',
                'average_heartrate' => 150,
                'total_elevation_gain' => 50,
            ],
        ]);

        $result = $this->callTool($user, 5);

        $this->assertSame(2, $result['count']);
        $this->assertEquals(15.0, $result['aggregates']['total_km']);
        $this->assertEquals(7.5, $result['aggregates']['avg_km_per_run']);
        $this->assertSame('5:00/km', $result['aggregates']['avg_pace']);
        $this->assertCount(2, $result['runs']);
        $this->assertSame('Morning Run', $result['runs'][0]['name']);
        $this->assertSame(1001, $result['runs'][0]['id']);
        $this->assertSame(1002, $result['runs'][1]['id']);
    }

    public function test_filters_out_non_run_activities(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $this->fakeStravaActivities([
            ['type' => 'Ride', 'name' => 'Commute', 'distance' => 20000, 'moving_time' => 3600, 'start_date' => '2026-04-15T07:00:00Z'],
            ['type' => 'Run', 'name' => 'Easy Run', 'distance' => 5000, 'moving_time' => 1500, 'start_date' => '2026-04-14T07:00:00Z'],
        ]);

        $result = $this->callTool($user, 10);

        $this->assertSame(1, $result['count']);
        $this->assertSame('Easy Run', $result['runs'][0]['name']);
    }

    public function test_returns_empty_message_when_no_runs_found(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $this->fakeStravaActivities([]);

        $result = $this->callTool($user, 5);

        $this->assertArrayHasKey('message', $result);
        $this->assertStringContainsString('No running activities', $result['message']);
    }

    public function test_oversamples_to_find_runs_among_other_activities(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $activities = [
            ['type' => 'Workout', 'name' => 'HIIT', 'distance' => 0, 'moving_time' => 2400, 'start_date' => '2026-04-15T07:00:00Z'],
            ['type' => 'Ride', 'name' => 'Commute', 'distance' => 20000, 'moving_time' => 3600, 'start_date' => '2026-04-14T07:00:00Z'],
            ['type' => 'Run', 'name' => 'Easy Run', 'distance' => 5000, 'moving_time' => 1500, 'start_date' => '2026-04-13T07:00:00Z'],
        ];
        $this->fakeStravaActivities($activities);

        $result = $this->callTool($user, 1);

        $this->assertSame(1, $result['count']);
        $this->assertSame('Easy Run', $result['runs'][0]['name']);
    }

    public function test_always_fetches_in_pages_of_thirty(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'strava.com/api/v3/athlete/activities*' => Http::response([], 200),
        ]);

        $this->callTool($user, 5);

        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'per_page=30');
        });
    }

    public function test_pages_when_first_page_has_insufficient_runs(): void
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);

        $fullPageOfNonRuns = array_fill(0, 30, [
            'type' => 'Workout', 'name' => 'HIIT', 'distance' => 0,
            'moving_time' => 2400, 'start_date' => '2026-04-10T07:00:00Z',
        ]);
        $pageWithRun = [
            ['type' => 'Run', 'name' => 'Found Me', 'distance' => 5000, 'moving_time' => 1500, 'start_date' => '2026-03-10T07:00:00Z'],
        ];

        Http::fakeSequence()
            ->push($fullPageOfNonRuns, 200)
            ->push($pageWithRun, 200);

        $result = $this->callTool($user, 1);

        $this->assertSame(1, $result['count']);
        $this->assertSame('Found Me', $result['runs'][0]['name']);
    }
}
