<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetActivityDetails;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class GetActivityDetailsTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function callTool(User $user, int $activityId): array
    {
        $tool = new GetActivityDetails($user);
        $request = new Request(['activity_id' => $activityId]);

        return json_decode($tool->handle($request), true);
    }

    public function test_returns_error_when_activity_does_not_exist(): void
    {
        $user = User::factory()->create();

        $result = $this->callTool($user, 999_999);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_returns_error_when_activity_belongs_to_another_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $strangerActivity = WearableActivity::factory()->create(['user_id' => $other->id]);

        $result = $this->callTool($user, $strangerActivity->id);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_returns_summary_for_an_activity_without_splits(): void
    {
        $user = User::factory()->create();
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'name' => 'Morning Run',
            'distance_meters' => 5000,
            'duration_seconds' => 1500,
            'average_pace_seconds_per_km' => 300,
            'average_heartrate' => 148,
            'max_heartrate' => 168,
            'elevation_gain_meters' => 32,
            'calories_kcal' => 410,
            'raw_data' => [],
        ]);

        $result = $this->callTool($user, $activity->id);

        $this->assertSame('Morning Run', $result['summary']['name']);
        $this->assertEquals(5.0, $result['summary']['distance_km']);
        $this->assertSame(148, $result['summary']['avg_heart_rate']);
        $this->assertSame(168, $result['summary']['max_heart_rate']);
        $this->assertSame(32, $result['summary']['total_elevation_gain_m']);
        $this->assertSame([], $result['splits']);
    }

    public function test_returns_pre_computed_splits_from_raw_data(): void
    {
        $user = User::factory()->create();
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5000,
            'raw_data' => [
                'splits' => [
                    ['distance_m' => 1000, 'duration_seconds' => 310, 'pace_seconds_per_km' => 310, 'average_heart_rate' => 145],
                    ['distance_m' => 1000, 'duration_seconds' => 305, 'pace_seconds_per_km' => 305, 'average_heart_rate' => 150],
                    ['distance_m' => 1000, 'duration_seconds' => 295, 'pace_seconds_per_km' => 295, 'average_heart_rate' => 158],
                ],
            ],
        ]);

        $result = $this->callTool($user, $activity->id);

        $this->assertCount(3, $result['splits']);
        $this->assertSame(310, $result['splits'][0]['pace_seconds_per_km']);
        $this->assertSame(295, $result['splits'][2]['pace_seconds_per_km']);
        $this->assertSame(145, $result['splits'][0]['average_heart_rate']);
    }
}
