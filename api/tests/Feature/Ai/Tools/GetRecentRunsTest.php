<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetRecentRuns;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class GetRecentRunsTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function callTool(User $user, ?int $limit): array
    {
        $tool = new GetRecentRuns($user);
        $request = new Request(['limit' => $limit]);

        return json_decode($tool->handle($request), true);
    }

    public function test_returns_message_when_user_has_no_synced_activities(): void
    {
        $user = User::factory()->create();

        $result = $this->callTool($user, 5);

        $this->assertArrayHasKey('message', $result);
        $this->assertStringContainsString('No running activities synced', $result['message']);
    }

    public function test_returns_recent_runs_with_aggregates(): void
    {
        $user = User::factory()->create();

        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Morning Run',
            'distance_meters' => 5000,
            'duration_seconds' => 1500,
            'average_pace_seconds_per_km' => 300,
            'start_date' => now()->subDay(),
            'average_heartrate' => 145,
        ]);
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Evening Run',
            'distance_meters' => 10000,
            'duration_seconds' => 3000,
            'average_pace_seconds_per_km' => 300,
            'start_date' => now()->subDays(2),
            'average_heartrate' => 150,
        ]);

        $result = $this->callTool($user, 5);

        $this->assertSame(2, $result['count']);
        $this->assertEquals(15.0, $result['aggregates']['total_km']);
        $this->assertEquals(7.5, $result['aggregates']['avg_km_per_run']);
        $this->assertSame('5:00/km', $result['aggregates']['avg_pace']);
        $this->assertCount(2, $result['runs']);
        $this->assertSame('Morning Run', $result['runs'][0]['name']);
    }

    public function test_filters_out_non_run_activities(): void
    {
        $user = User::factory()->create();

        WearableActivity::factory()->create(['user_id' => $user->id, 'type' => 'Ride']);
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'name' => 'Easy Run',
        ]);

        $result = $this->callTool($user, 10);

        $this->assertSame(1, $result['count']);
        $this->assertSame('Easy Run', $result['runs'][0]['name']);
    }

    public function test_only_returns_runs_belonging_to_caller(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();

        WearableActivity::factory()->create(['user_id' => $other->id, 'name' => 'Stranger']);
        WearableActivity::factory()->create(['user_id' => $user->id, 'name' => 'Mine']);

        $result = $this->callTool($user, 10);

        $this->assertSame(1, $result['count']);
        $this->assertSame('Mine', $result['runs'][0]['name']);
    }

    public function test_respects_limit(): void
    {
        $user = User::factory()->create();

        for ($i = 0; $i < 7; $i++) {
            WearableActivity::factory()->create([
                'user_id' => $user->id,
                'start_date' => now()->subDays($i),
            ]);
        }

        $result = $this->callTool($user, 3);

        $this->assertSame(3, $result['count']);
    }
}
