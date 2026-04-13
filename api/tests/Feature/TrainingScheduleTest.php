<?php

namespace Tests\Feature;

use App\Models\Race;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingScheduleTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_get_full_schedule(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id, 'week_number' => 1]);
        TrainingDay::factory()->count(7)->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/races/{$race->id}/schedule", $headers);

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertCount(7, $response->json('data.0.training_days'));
    }

    public function test_get_current_week(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'week_number' => 1,
            'starts_at' => now()->subWeeks(2)->startOfWeek(),
        ]);

        $currentWeek = TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'week_number' => 2,
            'starts_at' => now()->startOfWeek(),
        ]);
        TrainingDay::factory()->count(7)->create([
            'training_week_id' => $currentWeek->id,
            'date' => now(),
        ]);

        $response = $this->getJson("/api/v1/races/{$race->id}/schedule/current", $headers);

        $response->assertOk();
        $this->assertEquals($currentWeek->id, $response->json('data.id'));
    }

    public function test_get_training_day_detail(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['title' => $day->title]);
    }

    public function test_get_training_result(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $result = TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['compliance_score' => $result->compliance_score]);
    }

    public function test_training_day_without_result_returns_null(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $this->assertNull($response->json('data'));
    }
}
