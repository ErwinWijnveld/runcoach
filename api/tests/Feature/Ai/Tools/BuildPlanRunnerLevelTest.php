<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\BuildPlan;
use App\Enums\RunnerLevel;
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

class BuildPlanRunnerLevelTest extends TestCase
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
     * Self-reported baseline keeps the snapshot deterministic across
     * runs so the only variable is runner_level.
     */
    private function user(): User
    {
        return User::factory()->create([
            'self_reported_weekly_km' => 25.0,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now(),
            'runner_level' => 'intermediate',
        ]);
    }

    private function args(string $runnerLevel): array
    {
        return [
            'goal_type' => 'race',
            'goal_name' => 'Runner-Level Test',
            'distance_meters' => 21097,
            'target_date' => now()->addWeeks(12)->endOfWeek()->toDateString(),
            'goal_time_seconds' => 6300,
            'pr_current_seconds' => null,
            'days_per_week' => 4,
            'preferred_weekdays' => [2, 4, 6, 7],
            'coach_style' => 'balanced',
            'additional_notes' => null,
            'run_type_preferences' => null,
            'intensity_bias' => 'standard',
            'runner_level' => $runnerLevel,
        ];
    }

    /**
     * Strip volatile fields (proposal id, timestamps) before comparing
     * two plan payloads. The comparison surface is the schedule shape,
     * paces, volumes, and titles — i.e. what the runner sees.
     *
     * @param  array<string, mixed>  $payload
     * @return list<array<string, mixed>>
     */
    private function planFingerprint(array $payload): array
    {
        return array_map(function (array $week): array {
            return [
                'week_number' => $week['week_number'] ?? null,
                'total_km' => $week['total_km'] ?? null,
                'days' => array_map(fn (array $d): array => [
                    'day_of_week' => $d['day_of_week'] ?? null,
                    'type' => $d['type'] ?? null,
                    'target_km' => $d['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $d['target_pace_seconds_per_km'] ?? null,
                ], $week['days'] ?? []),
            ];
        }, $payload['schedule']['weeks'] ?? []);
    }

    public function test_runner_level_persists_on_user_after_handle(): void
    {
        $user = $this->user();
        $this->assertSame(RunnerLevel::Intermediate, $user->runner_level);

        $this->makeTool($user)->handle(new Request($this->args('beginner')));

        $this->assertSame(RunnerLevel::Beginner, $user->fresh()->runner_level);
    }

    public function test_runner_level_defaults_to_intermediate_when_missing(): void
    {
        $user = $this->user();
        $args = $this->args('intermediate');
        unset($args['runner_level']);

        $result = json_decode($this->makeTool($user)->handle(new Request($args)), true);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame(RunnerLevel::Intermediate, $user->fresh()->runner_level);
    }

    /**
     * Invariant within a tone bucket: the three Expert-tier UI cases
     * (Advanced / SubElite / Elite) collapse to the same `RunnerToneBucket::Expert`
     * and therefore must produce identical plan content.
     */
    public function test_plan_content_is_identical_within_expert_tier(): void
    {
        $userAdvanced = $this->user();
        $resultAdvanced = json_decode(
            $this->makeTool($userAdvanced)->handle(new Request($this->args('advanced'))),
            true,
        );

        $userElite = $this->user();
        $resultElite = json_decode(
            $this->makeTool($userElite)->handle(new Request($this->args('elite'))),
            true,
        );

        $advancedProposal = CoachProposal::findOrFail($resultAdvanced['proposal_id']);
        $eliteProposal = CoachProposal::findOrFail($resultElite['proposal_id']);

        $this->assertEquals(
            $this->planFingerprint($advancedProposal->payload),
            $this->planFingerprint($eliteProposal->payload),
            'Advanced/SubElite/Elite all map to RunnerToneBucket::Expert — plan content must match.',
        );
    }

    /**
     * Novice and Standard tone buckets share the same interval progression
     * (5×400 / 5×800 / 6×800), so beginner + intermediate must match.
     */
    public function test_plan_content_is_identical_within_non_expert_tiers(): void
    {
        $userBeginner = $this->user();
        $resultBeginner = json_decode(
            $this->makeTool($userBeginner)->handle(new Request($this->args('beginner'))),
            true,
        );

        $userIntermediate = $this->user();
        $resultIntermediate = json_decode(
            $this->makeTool($userIntermediate)->handle(new Request($this->args('intermediate'))),
            true,
        );

        $beginnerProposal = CoachProposal::findOrFail($resultBeginner['proposal_id']);
        $intermediateProposal = CoachProposal::findOrFail($resultIntermediate['proposal_id']);

        $this->assertEquals(
            $this->planFingerprint($beginnerProposal->payload),
            $this->planFingerprint($intermediateProposal->payload),
            'Beginner + Intermediate share the same Novice/Standard interval progression.',
        );
    }

    /**
     * Cross-bucket: a beginner and an elite runner should NOT receive the
     * same interval shape. Expert tier starts at 800m reps and scales to
     * 1200m; Novice/Standard stays on 400m → 800m. The fingerprint surface
     * picks this up via `target_km` per interval day (the estimator's km
     * contribution scales with rep distance × count).
     */
    public function test_plan_content_differs_between_novice_and_expert(): void
    {
        $userBeginner = $this->user();
        $resultBeginner = json_decode(
            $this->makeTool($userBeginner)->handle(new Request($this->args('beginner'))),
            true,
        );

        $userElite = $this->user();
        $resultElite = json_decode(
            $this->makeTool($userElite)->handle(new Request($this->args('elite'))),
            true,
        );

        $beginnerProposal = CoachProposal::findOrFail($resultBeginner['proposal_id']);
        $eliteProposal = CoachProposal::findOrFail($resultElite['proposal_id']);

        $this->assertNotEquals(
            $this->planFingerprint($beginnerProposal->payload),
            $this->planFingerprint($eliteProposal->payload),
            'Expert tier must use a longer-rep interval progression than Novice/Standard.',
        );
    }
}
