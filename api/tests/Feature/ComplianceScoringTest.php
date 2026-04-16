<?php

namespace Tests\Feature;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Services\ComplianceScoringService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ComplianceScoringTest extends TestCase
{
    use LazilyRefreshDatabase;

    private ComplianceScoringService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ComplianceScoringService;
    }

    private function createUserWithPlan(array $dayOverrides = []): array
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek(),
        ]);
        $day = TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Tempo,
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 285,
            'target_heart_rate_zone' => 3,
        ], $dayOverrides));

        return [$user, $day];
    }

    public function test_perfect_compliance_scores_10(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'moving_time_seconds' => 2280,
            'average_heartrate' => 160,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertGreaterThanOrEqual(9.0, (float) $result->compliance_score);
    }

    public function test_no_matching_day_creates_no_result(): void
    {
        $user = User::factory()->create();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertDatabaseCount('training_results', 0);
    }

    public function test_missing_heart_rate_redistributes_weights(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'moving_time_seconds' => 2280,
            'average_heartrate' => null,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertNull($result->heart_rate_score);
        $this->assertGreaterThan(0, (float) $result->compliance_score);
    }

    public function test_rest_day_activity_does_not_match(): void
    {
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Rest,
            'target_km' => null,
            'target_pace_seconds_per_km' => null,
        ]);

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5000,
            'moving_time_seconds' => 1800,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);
        $this->assertNull($day->fresh()->result);
    }
}
