<?php

namespace Tests\Feature;

use App\Enums\RaceStatus;
use App\Enums\TrainingType;
use App\Models\Race;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
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
        $race = Race::factory()->create([
            'user_id' => $user->id,
            'status' => RaceStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'race_id' => $race->id,
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
            'active_race',
        ]);
    }

    public function test_dashboard_with_no_active_race(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $this->assertNull($response->json('active_race'));
    }
}
