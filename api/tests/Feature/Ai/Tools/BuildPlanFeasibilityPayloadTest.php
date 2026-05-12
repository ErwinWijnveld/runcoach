<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\BuildPlan;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\Onboarding\FitnessSnapshotService;
use App\Services\Onboarding\PlanAmbitionAnalyzer;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class BuildPlanFeasibilityPayloadTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_payload_includes_ambition_when_goal_has_time(): void
    {
        $user = $this->raceUser();
        $tool = $this->makeTool($user);

        $result = json_decode($tool->handle(new Request([
            'goal_type' => 'race',
            'distance_meters' => 5000,
            'target_date' => now()->addWeeks(12)->endOfWeek()->toDateString(),
            'goal_time_seconds' => 1320, // 22:00 — ambitious for a 20km/week baseline
            'pr_current_seconds' => null,
            'goal_name' => 'Spring 5K',
            'days_per_week' => 4,
            'preferred_weekdays' => [1, 3, 5, 6],
            'coach_style' => 'balanced',
            'run_type_preferences' => null,
            'additional_notes' => null,
            'intensity_bias' => null,
        ])), true);

        $this->assertTrue($result['requires_approval']);

        $proposal = CoachProposal::findOrFail($result['proposal_id']);
        $this->assertArrayHasKey('ambition', $proposal->payload);

        $ambition = $proposal->payload['ambition'];
        $this->assertArrayHasKey('feasibility_pct', $ambition);
        $this->assertArrayHasKey('verdict_zone', $ambition);
        $this->assertArrayHasKey('adjust_prefill', $ambition);
        $this->assertContains($ambition['verdict_zone'], ['ok', 'stretch', 'unrealistic']);
        $this->assertIsInt($ambition['feasibility_pct']);
        $this->assertGreaterThanOrEqual(0, $ambition['feasibility_pct']);
        $this->assertLessThanOrEqual(100, $ambition['feasibility_pct']);
    }

    public function test_payload_omits_ambition_for_general_fitness_goal(): void
    {
        $user = $this->raceUser();
        $tool = $this->makeTool($user);

        $result = json_decode($tool->handle(new Request([
            'goal_type' => 'general_fitness',
            'distance_meters' => null,
            'target_date' => null,
            'goal_time_seconds' => null,
            'pr_current_seconds' => null,
            'goal_name' => 'Stay fit',
            'days_per_week' => 3,
            'preferred_weekdays' => [1, 3, 5],
            'coach_style' => 'balanced',
            'run_type_preferences' => null,
            'additional_notes' => null,
            'intensity_bias' => null,
        ])), true);

        $this->assertTrue($result['requires_approval']);

        $proposal = CoachProposal::findOrFail($result['proposal_id']);
        $this->assertArrayNotHasKey('ambition', $proposal->payload);
    }

    private function makeTool(User $user): BuildPlan
    {
        return new BuildPlan(
            user: $user,
            snapshots: app(FitnessSnapshotService::class),
            builder: app(TrainingPlanBuilder::class),
            optimizer: app(PlanOptimizerService::class),
            proposals: app(ProposalService::class),
            ambition: app(PlanAmbitionAnalyzer::class),
        );
    }

    private function raceUser(): User
    {
        return User::factory()->create([
            'self_reported_weekly_km' => 20.0,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now(),
            'intensity_bias' => 'standard',
        ]);
    }
}
