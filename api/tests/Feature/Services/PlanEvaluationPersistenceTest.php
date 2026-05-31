<?php

namespace Tests\Feature\Services;

use App\Enums\PlanEvaluationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\PlanEvaluation;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

/**
 * Verifies that the `evaluations[]` payload emitted by
 * `TrainingPlanBuilder::scheduleEvaluations` is actually persisted as
 * `PlanEvaluation` rows when a `CreateSchedule` proposal is accepted.
 */
class PlanEvaluationPersistenceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_persists_evaluations_linked_to_correct_training_week(): void
    {
        $user = User::factory()->create();
        $weekStart = now()->startOfWeek();
        $week2Sunday = $weekStart->copy()->addWeeks(1)->addDays(6)->toDateString();
        $week4Sunday = $weekStart->copy()->addWeeks(3)->addDays(6)->toDateString();

        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Test 10K',
                'distance' => '10k',
                'goal_time_seconds' => 3000,
                'target_date' => $weekStart->copy()->addWeeks(5)->toDateString(),
                'schedule' => [
                    'weeks' => $this->buildWeeks($weekStart),
                ],
                'evaluations' => [
                    ['week_number' => 2, 'scheduled_for' => $week2Sunday],
                    ['week_number' => 4, 'scheduled_for' => $week4Sunday],
                ],
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $goal = $user->goals()->firstOrFail();
        $evaluations = PlanEvaluation::where('goal_id', $goal->id)
            ->orderBy('scheduled_for')
            ->get();

        $this->assertCount(2, $evaluations);

        $this->assertSame($week2Sunday, $evaluations[0]->scheduled_for->toDateString());
        $this->assertSame(PlanEvaluationStatus::Pending, $evaluations[0]->status);
        $this->assertSame($user->id, $evaluations[0]->user_id);

        $week2 = $goal->trainingWeeks()->where('week_number', 2)->firstOrFail();
        $this->assertSame($week2->id, $evaluations[0]->training_week_id);

        $week4 = $goal->trainingWeeks()->where('week_number', 4)->firstOrFail();
        $this->assertSame($week4->id, $evaluations[1]->training_week_id);
    }

    public function test_skips_past_dated_evaluations(): void
    {
        $user = User::factory()->create();
        $weekStart = now()->startOfWeek();

        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Test',
                'distance' => '5k',
                'target_date' => $weekStart->copy()->addWeeks(4)->toDateString(),
                'schedule' => ['weeks' => $this->buildWeeks($weekStart)],
                'evaluations' => [
                    // Past — should be skipped.
                    ['week_number' => 1, 'scheduled_for' => now()->subDays(10)->toDateString()],
                    // Future — should persist.
                    ['week_number' => 2, 'scheduled_for' => now()->addDays(7)->toDateString()],
                ],
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $goal = $user->goals()->firstOrFail();
        $this->assertSame(1, PlanEvaluation::where('goal_id', $goal->id)->count());
    }

    public function test_no_evaluations_section_is_a_noop(): void
    {
        $user = User::factory()->create();
        $weekStart = now()->startOfWeek();

        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Test',
                'distance' => '5k',
                'target_date' => $weekStart->copy()->addWeeks(4)->toDateString(),
                'schedule' => ['weeks' => $this->buildWeeks($weekStart)],
                // No 'evaluations' key.
            ],
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $this->assertSame(0, PlanEvaluation::count());
    }

    /**
     * Build 4 weeks of payload data, putting each day on day_of_week=7
     * (Sunday) so `applyCreateSchedule`'s past-date filter doesn't drop
     * them on the run-day. Each week ends up with exactly one Sunday day,
     * which is enough for the week itself to persist with the same
     * week_number we wrote.
     *
     * @return list<array<string, mixed>>
     */
    private function buildWeeks($weekStart): array
    {
        $weeks = [];
        for ($i = 1; $i <= 4; $i++) {
            $weeks[] = [
                'week_number' => $i,
                'focus' => 'Build',
                'total_km' => 20 + $i,
                'days' => [
                    [
                        'day_of_week' => 7,
                        'type' => 'easy',
                        'title' => 'Easy long',
                        'target_km' => 5 + $i,
                    ],
                ],
            ];
        }

        return $weeks;
    }
}
