<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\GetRunningProfile;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class GetRunningProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function callTool(User $user): array
    {
        $tool = new GetRunningProfile($user);
        $request = new Request([]);

        return json_decode($tool->handle($request), true);
    }

    public function test_returns_profile_when_one_exists_for_the_user(): void
    {
        $user = User::factory()->create();

        UserRunningProfile::create([
            'user_id' => $user->id,
            'analyzed_at' => now()->subDay(),
            'data_start_date' => now()->subYear()->toDateString(),
            'data_end_date' => now()->toDateString(),
            'metrics' => [
                'weekly_avg_km' => 35.5,
                'weekly_avg_runs' => 4,
                'avg_pace_seconds_per_km' => 310,
                'consistency_score' => 82,
                'total_runs_12mo' => 180,
                'total_distance_km_12mo' => 1820.0,
            ],
            'narrative_summary' => 'Strong, consistent runner with solid base fitness.',
        ]);

        $result = $this->callTool($user);

        $this->assertArrayHasKey('analyzed_at', $result);
        $this->assertArrayHasKey('metrics', $result);
        $this->assertArrayHasKey('narrative_summary', $result);
        $this->assertEquals(35.5, $result['metrics']['weekly_avg_km']);
        $this->assertSame('Strong, consistent runner with solid base fitness.', $result['narrative_summary']);
    }

    public function test_returns_message_when_no_profile_cached(): void
    {
        $user = User::factory()->create();

        $result = $this->callTool($user);

        $this->assertArrayHasKey('message', $result);
        $this->assertStringContainsString('No running profile cached', $result['message']);
    }

    public function test_does_not_return_another_users_profile(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        UserRunningProfile::create([
            'user_id' => $otherUser->id,
            'analyzed_at' => now(),
            'data_start_date' => now()->subYear()->toDateString(),
            'data_end_date' => now()->toDateString(),
            'metrics' => ['weekly_avg_km' => 50.0],
            'narrative_summary' => 'Other user.',
        ]);

        $result = $this->callTool($user);

        $this->assertArrayHasKey('message', $result);
    }
}
