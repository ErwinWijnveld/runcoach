<?php

namespace Tests\Feature;

use App\Enums\GoalDistance;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ProposalServiceDistanceNormalizationTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function acceptWithDistance(mixed $distance): Goal
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Test',
                'distance' => $distance,
                'goal_time_seconds' => 3600,
                'target_date' => '2026-09-15',
                'schedule' => ['weeks' => []],
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        return $user->goals()->firstOrFail();
    }

    public function test_int_meters_10000_maps_to_10k_enum(): void
    {
        $goal = $this->acceptWithDistance(10000);

        $this->assertSame(GoalDistance::TenK, $goal->distance);
        $this->assertNull($goal->custom_distance_meters);
    }

    public function test_int_meters_21097_maps_to_half_marathon(): void
    {
        $goal = $this->acceptWithDistance(21097);
        $this->assertSame(GoalDistance::HalfMarathon, $goal->distance);
    }

    public function test_int_meters_42195_maps_to_marathon(): void
    {
        $goal = $this->acceptWithDistance(42195);
        $this->assertSame(GoalDistance::Marathon, $goal->distance);
    }

    public function test_non_standard_meters_map_to_custom_with_meters_stored(): void
    {
        $goal = $this->acceptWithDistance(15000);
        $this->assertSame(GoalDistance::Custom, $goal->distance);
        $this->assertSame(15000, $goal->custom_distance_meters);
    }

    public function test_enum_string_passes_through(): void
    {
        $goal = $this->acceptWithDistance('half_marathon');
        $this->assertSame(GoalDistance::HalfMarathon, $goal->distance);
        $this->assertNull($goal->custom_distance_meters);
    }

    public function test_null_distance_is_preserved(): void
    {
        $goal = $this->acceptWithDistance(null);
        $this->assertNull($goal->distance);
        $this->assertNull($goal->custom_distance_meters);
    }

    public function test_hr_zone_normalizes_zn_string_to_int(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'general_fitness',
                'goal_name' => 'Fitness',
                'distance' => null,
                'goal_time_seconds' => null,
                'target_date' => null,
                'schedule' => [
                    'weeks' => [[
                        'week_number' => 1,
                        'focus' => 'Base',
                        'total_km' => 5,
                        'days' => [[
                            'day_of_week' => now()->isoWeekday(),
                            'type' => 'easy',
                            'title' => 'Easy run',
                            'target_km' => 5,
                            'target_pace_seconds_per_km' => 360,
                            'target_heart_rate_zone' => 'Z2',
                        ]],
                    ]],
                ],
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $goal = $user->goals()->firstOrFail();
        $day = $goal->trainingWeeks()->firstOrFail()->trainingDays()->firstOrFail();
        $this->assertSame(2, $day->target_heart_rate_zone);
    }

    public function test_hr_zone_normalizes_out_of_range_to_null(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'general_fitness',
                'goal_name' => 'Fitness',
                'distance' => null,
                'goal_time_seconds' => null,
                'target_date' => null,
                'schedule' => [
                    'weeks' => [[
                        'week_number' => 1,
                        'focus' => 'Base',
                        'total_km' => 5,
                        'days' => [[
                            'day_of_week' => now()->isoWeekday(),
                            'type' => 'easy',
                            'title' => 'Easy run',
                            'target_km' => 5,
                            'target_pace_seconds_per_km' => 360,
                            'target_heart_rate_zone' => 'Z9',
                        ]],
                    ]],
                ],
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $day = $user->goals()->firstOrFail()->trainingWeeks()->firstOrFail()->trainingDays()->firstOrFail();
        $this->assertNull($day->target_heart_rate_zone);
    }
}
