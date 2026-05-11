<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\BuildPlan;
use App\Enums\IntensityBias;
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

class BuildPlanIntensityBiasTest extends TestCase
{
    use LazilyRefreshDatabase;

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

    /**
     * Self-reported baseline gives the snapshot deterministic inputs
     * (Tier-0 override in FitnessSnapshotService), so the only variable
     * across runs is the intensity_bias value.
     */
    private function user(): User
    {
        return User::factory()->create([
            'self_reported_weekly_km' => 20.0,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now(),
            'intensity_bias' => 'standard',
        ]);
    }

    private function buildArgs(string $intensityBias): array
    {
        return [
            'goal_type' => 'race',
            'goal_name' => 'Intensity Test Race',
            'distance_meters' => 21097,
            'target_date' => now()->addWeeks(12)->endOfWeek()->toDateString(),
            'goal_time_seconds' => 6300,
            'pr_current_seconds' => null,
            'days_per_week' => 4,
            'preferred_weekdays' => [2, 4, 6, 7],
            'coach_style' => 'balanced',
            'additional_notes' => null,
            'run_type_preferences' => null,
            'intensity_bias' => $intensityBias,
        ];
    }

    private function peakWeeklyKm(array $proposalPayload): float
    {
        $max = 0.0;
        foreach ($proposalPayload['schedule']['weeks'] ?? [] as $w) {
            $max = max($max, (float) ($w['total_km'] ?? 0));
        }

        return $max;
    }

    public function test_push_me_harder_lifts_peak_volume_above_standard(): void
    {
        $userStandard = $this->user();
        $resultStandard = json_decode(
            $this->makeTool($userStandard)->handle(new Request($this->buildArgs('standard'))),
            true,
        );

        $userHard = $this->user();
        $resultHard = json_decode(
            $this->makeTool($userHard)->handle(new Request($this->buildArgs('push_me_harder'))),
            true,
        );

        $standardProposal = CoachProposal::findOrFail($resultStandard['proposal_id']);
        $hardProposal = CoachProposal::findOrFail($resultHard['proposal_id']);

        $peakStandard = $this->peakWeeklyKm($standardProposal->payload);
        $peakHard = $this->peakWeeklyKm($hardProposal->payload);

        $this->assertGreaterThan($peakStandard, $peakHard, "Push-me-harder peak ({$peakHard}) should exceed standard ({$peakStandard})");
    }

    public function test_take_it_easy_lowers_peak_volume_below_standard(): void
    {
        $userStandard = $this->user();
        $resultStandard = json_decode(
            $this->makeTool($userStandard)->handle(new Request($this->buildArgs('standard'))),
            true,
        );

        $userEasy = $this->user();
        $resultEasy = json_decode(
            $this->makeTool($userEasy)->handle(new Request($this->buildArgs('take_it_easy'))),
            true,
        );

        $standardProposal = CoachProposal::findOrFail($resultStandard['proposal_id']);
        $easyProposal = CoachProposal::findOrFail($resultEasy['proposal_id']);

        $peakStandard = $this->peakWeeklyKm($standardProposal->payload);
        $peakEasy = $this->peakWeeklyKm($easyProposal->payload);

        $this->assertLessThan($peakStandard, $peakEasy, "Take-it-easy peak ({$peakEasy}) should be below standard ({$peakStandard})");
    }

    public function test_intensity_bias_persists_on_user_after_handle(): void
    {
        $user = $this->user();
        $this->assertSame(IntensityBias::Standard, $user->intensity_bias);

        $this->makeTool($user)->handle(new Request($this->buildArgs('push_me_harder')));

        $this->assertSame(IntensityBias::PushMeHarder, $user->fresh()->intensity_bias);
    }

    public function test_default_intensity_bias_when_missing_is_standard(): void
    {
        $user = $this->user();
        $args = $this->buildArgs('standard');
        unset($args['intensity_bias']);

        $result = json_decode($this->makeTool($user)->handle(new Request($args)), true);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame(IntensityBias::Standard, $user->fresh()->intensity_bias);
    }
}
