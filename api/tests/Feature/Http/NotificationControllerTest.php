<?php

namespace Tests\Feature\Http;

use App\Enums\GoalStatus;
use App\Enums\PlanEvaluationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\PlanEvaluation;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Mockery\MockInterface;
use Tests\TestCase;

class NotificationControllerTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_index_returns_pending_notifications_for_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();

        UserNotification::factory()->create(['user_id' => $user->id]);
        UserNotification::factory()->dismissed()->create(['user_id' => $user->id]);
        UserNotification::factory()->create(['user_id' => $other->id]);

        $this->actingAs($user)
            ->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_accept_plan_evaluation_applies_proposal_and_marks_accepted(): void
    {
        [$user, $goal] = $this->activeGoal('2026-06-15');

        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'status' => ProposalStatus::Pending,
            'payload' => ['goal_id' => $goal->id, 'schedule' => ['weeks' => []]],
        ]);

        $notification = UserNotification::factory()->create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PLAN_EVALUATION,
        ]);

        $evaluation = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'proposal_id' => $proposal->id,
            'notification_id' => $notification->id,
            'status' => PlanEvaluationStatus::Ready,
        ]);

        $this->mock(ProposalService::class, function (MockInterface $mock) use ($proposal, $user) {
            $mock->shouldReceive('apply')
                ->once()
                ->with(Mockery::on(fn ($p) => $p->id === $proposal->id), Mockery::on(fn ($u) => $u->id === $user->id));
        });

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/accept")
            ->assertOk();

        $this->assertSame(UserNotification::STATUS_ACCEPTED, $notification->fresh()->status);
        $this->assertSame(PlanEvaluationStatus::Accepted, $evaluation->fresh()->status);
    }

    public function test_accept_plan_evaluation_without_proposal_just_marks_accepted(): void
    {
        [$user, $goal] = $this->activeGoal('2026-06-15');

        $notification = UserNotification::factory()->create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PLAN_EVALUATION,
        ]);

        $evaluation = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'notification_id' => $notification->id,
            'proposal_id' => null,
            'status' => PlanEvaluationStatus::NoChangeNeeded,
        ]);

        $this->mock(ProposalService::class, function (MockInterface $mock) {
            $mock->shouldNotReceive('apply');
        });

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/accept")
            ->assertOk();

        $this->assertSame(UserNotification::STATUS_ACCEPTED, $notification->fresh()->status);
        $this->assertSame(PlanEvaluationStatus::Accepted, $evaluation->fresh()->status);
    }

    public function test_dismiss_plan_evaluation_marks_evaluation_dismissed_too(): void
    {
        [$user, $goal] = $this->activeGoal('2026-06-15');

        $notification = UserNotification::factory()->create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PLAN_EVALUATION,
        ]);

        $evaluation = PlanEvaluation::factory()->create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'notification_id' => $notification->id,
            'status' => PlanEvaluationStatus::Ready,
        ]);

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/dismiss")
            ->assertOk();

        $this->assertSame(UserNotification::STATUS_DISMISSED, $notification->fresh()->status);
        $this->assertSame(PlanEvaluationStatus::Dismissed, $evaluation->fresh()->status);
    }

    public function test_cannot_act_on_another_users_notification(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $notification = UserNotification::factory()->create(['user_id' => $other->id]);

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/accept")
            ->assertForbidden();
    }

    public function test_cannot_accept_already_handled_notification(): void
    {
        $user = User::factory()->create();
        $notification = UserNotification::factory()->dismissed()->create(['user_id' => $user->id]);

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/accept")
            ->assertStatus(422);
    }

    /**
     * @return array{0: User, 1: Goal, 2: TrainingWeek}
     */
    private function activeGoal(string $targetDate): array
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
            'target_date' => $targetDate,
        ]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);

        return [$user, $goal, $week];
    }
}
