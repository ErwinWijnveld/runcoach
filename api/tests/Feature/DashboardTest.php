<?php

namespace Tests\Feature;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_dashboard_returns_weekly_summary(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek(),
            'total_km' => 42.5,
        ]);

        $completedDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->subDay(),
            'type' => TrainingType::Easy,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $completedDay->id,
            'actual_km' => 5.0,
            'compliance_score' => 8.5,
        ]);

        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->addDay(),
            'type' => TrainingType::Tempo,
        ]);

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $response->assertJsonStructure([
            'weekly_summary' => ['total_km_planned', 'total_km_completed', 'compliance_avg'],
            'next_training',
            'active_goal' => ['id', 'name', 'type', 'distance', 'target_date', 'weeks_until_target_date'],
        ]);
    }

    public function test_dashboard_with_no_active_goal(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $this->assertNull($response->json('active_goal'));
    }

    public function test_dashboard_includes_recent_runs_with_linkage(): void
    {
        [$user, $headers] = $this->authUser();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek(),
        ]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->subDays(2),
        ]);

        $linked = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => now()->subDays(2),
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $linked->id,
            'compliance_score' => 8.2,
        ]);

        $unlinked = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => now()->subDay(),
        ]);

        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Ride',
            'start_date' => now(),
        ]);

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $runs = $response->json('recent_runs');
        $this->assertCount(2, $runs);
        $this->assertSame($unlinked->id, $runs[0]['run']['id']);
        $this->assertNull($runs[0]['training_day_id']);
        $this->assertNull($runs[0]['compliance_score']);
        $this->assertSame($linked->id, $runs[1]['run']['id']);
        $this->assertSame($day->id, $runs[1]['training_day_id']);
        $this->assertSame(8.2, $runs[1]['compliance_score']);
    }

    public function test_recent_runs_are_capped_at_five_newest(): void
    {
        [$user, $headers] = $this->authUser();
        Goal::factory()->create(['user_id' => $user->id, 'status' => GoalStatus::Active]);

        foreach (range(1, 7) as $i) {
            WearableActivity::factory()->create([
                'user_id' => $user->id,
                'type' => 'Run',
                'start_date' => now()->subDays($i),
            ]);
        }

        $runs = $this->getJson('/api/v1/dashboard', $headers)->json('recent_runs');

        $this->assertCount(5, $runs);
        $dates = array_map(fn (array $r) => $r['run']['start_date'], $runs);
        $sorted = $dates;
        rsort($sorted);
        $this->assertSame($sorted, $dates);
    }

    public function test_dashboard_without_active_goal_still_returns_recent_runs(): void
    {
        [$user, $headers] = $this->authUser();
        WearableActivity::factory()->create(['user_id' => $user->id, 'type' => 'Run']);

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $this->assertNull($response->json('active_goal'));
        $this->assertCount(1, $response->json('recent_runs'));
    }
}
