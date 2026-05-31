<?php

namespace Tests\Feature\Console;

use App\Enums\GoalStatus;
use App\Enums\PlanEvaluationStatus;
use App\Jobs\GeneratePlanEvaluation;
use App\Models\Goal;
use App\Models\PlanEvaluation;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class RunPlanEvaluationsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_dispatches_jobs_for_due_pending_evaluations(): void
    {
        Queue::fake();

        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);

        $due = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => now()->subDay()->toDateString(),
            'status' => PlanEvaluationStatus::Pending,
        ]);

        $future = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => now()->addDays(7)->toDateString(),
            'status' => PlanEvaluationStatus::Pending,
        ]);

        $this->artisan('plan:run-evaluations')->assertSuccessful();

        Queue::assertPushed(GeneratePlanEvaluation::class, fn ($job) => $job->evaluationId === $due->id);
        Queue::assertNotPushed(GeneratePlanEvaluation::class, fn ($job) => $job->evaluationId === $future->id);
    }

    public function test_skips_evaluations_for_inactive_goals(): void
    {
        Queue::fake();

        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Completed,
        ]);

        PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => now()->subDay()->toDateString(),
            'status' => PlanEvaluationStatus::Pending,
        ]);

        $this->artisan('plan:run-evaluations')->assertSuccessful();

        Queue::assertNothingPushed();
    }

    public function test_skips_already_processed_evaluations(): void
    {
        Queue::fake();

        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);

        PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => now()->subDays(3)->toDateString(),
            'status' => PlanEvaluationStatus::Accepted,
        ]);

        $this->artisan('plan:run-evaluations')->assertSuccessful();

        Queue::assertNothingPushed();
    }

    public function test_date_option_overrides_today(): void
    {
        Queue::fake();

        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);

        $futureDate = now()->addDays(30)->toDateString();

        $eval = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'scheduled_for' => $futureDate,
            'status' => PlanEvaluationStatus::Pending,
        ]);

        // Without --date, today < scheduled_for → no dispatch.
        $this->artisan('plan:run-evaluations')->assertSuccessful();
        Queue::assertNothingPushed();

        // With --date overriding to that future day, the eval becomes due.
        $this->artisan('plan:run-evaluations', ['--date' => $futureDate])->assertSuccessful();
        Queue::assertPushed(GeneratePlanEvaluation::class, fn ($job) => $job->evaluationId === $eval->id);
    }
}
