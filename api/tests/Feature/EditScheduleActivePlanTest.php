<?php

namespace Tests\Feature;

use App\Ai\Tools\EditSchedule;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Services\ProposalService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class EditScheduleActivePlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * Build a runner with an active goal + this week and next week of
     * training days. `starts_at` is this week Monday so dates are realistic.
     */
    private function seedActiveGoal(User $user): Goal
    {
        $monday = Carbon::now()->startOfWeek();

        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'type' => GoalType::Race,
            'name' => 'Test Race',
            'distance' => '10k',
            'custom_distance_meters' => null,
            'goal_time_seconds' => 3000,
            'target_date' => $monday->copy()->addWeeks(3)->toDateString(),
            'status' => GoalStatus::Active,
        ]);

        foreach ([1, 2] as $weekNumber) {
            $weekStart = $monday->copy()->addWeeks($weekNumber - 1);
            $week = TrainingWeek::factory()->create([
                'goal_id' => $goal->id,
                'week_number' => $weekNumber,
                'starts_at' => $weekStart,
                'total_km' => 20,
                'focus' => "Week {$weekNumber}",
            ]);

            foreach ([2, 4, 6] as $dow) {
                TrainingDay::factory()->create([
                    'training_week_id' => $week->id,
                    'date' => $weekStart->copy()->addDays($dow - 1),
                    'type' => 'easy',
                    'title' => 'Run',
                    'target_km' => 5,
                    'target_pace_seconds_per_km' => 390,
                    'target_heart_rate_zone' => 2,
                    'order' => $dow,
                ]);
            }
        }

        return $goal;
    }

    /**
     * @param  array<string, mixed>  $input
     * @return array<string, mixed>
     */
    private function invoke(User $user, array $input): array
    {
        $tool = new EditSchedule($user);
        $result = $tool->handle(new Request($input));

        return json_decode($result, true);
    }

    public function test_auto_targets_active_goal_when_no_pending_proposal(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 2, 'day_of_week' => 4, 'fields' => ['target_km' => 8]],
            ]),
        ]);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame(ProposalType::EditActivePlan->value, $result['proposal_type']);
        $this->assertArrayHasKey('goal_id', $result['payload']);
    }

    public function test_pending_proposal_wins_over_active_goal_in_auto_target(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => [
                'goal_name' => 'Proposed',
                'schedule' => ['weeks' => [['week_number' => 1, 'focus' => 'P', 'total_km' => 5, 'days' => [['day_of_week' => 2, 'type' => 'easy', 'title' => 'E', 'target_km' => 5]]]]],
            ],
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 6]],
            ]),
        ]);

        // Should target the pending proposal, so type is create_schedule.
        $this->assertSame(ProposalType::CreateSchedule->value, $result['proposal_type']);
    }

    public function test_explicit_goal_id_targets_active_plan(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 2, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'title' => 'Sunday shakeout', 'target_km' => 3]],
            ]),
        ]);

        $this->assertSame(ProposalType::EditActivePlan->value, $result['proposal_type']);
        $week2 = collect($result['payload']['schedule']['weeks'])->firstWhere('week_number', 2);
        $dows = array_column($week2['days'], 'day_of_week');
        $this->assertContains(7, $dows);
    }

    public function test_passing_both_ids_returns_error(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'goal_id' => $goal->id,
            'operations' => json_encode([['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 5]]]),
        ]);

        $this->assertStringContainsString('not both', $result['error']);
    }

    public function test_non_active_goal_is_rejected(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Paused,
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 5]]]),
        ]);

        $this->assertStringContainsString('not active', $result['error']);
    }

    public function test_cross_user_goal_is_not_accessible(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $other->id,
            'status' => GoalStatus::Active,
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 5]]]),
        ]);

        $this->assertStringContainsString('Goal not found', $result['error']);
    }

    public function test_accepting_adds_new_day_to_active_plan(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        $toolResult = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 2, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'title' => 'Sunday', 'target_km' => 3, 'target_pace_seconds_per_km' => 400, 'target_heart_rate_zone' => 2]],
            ]),
        ]);

        $proposal = CoachProposal::create([
            'agent_message_id' => fake()->uuid(),
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'payload' => $toolResult['payload'],
            'status' => ProposalStatus::Pending,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $week2 = $goal->trainingWeeks()->where('week_number', 2)->firstOrFail();
        $this->assertSame(4, $week2->trainingDays()->count());
        $sunday = $week2->trainingDays()->where('order', 7)->firstOrFail();
        $this->assertSame(TrainingType::Easy, $sunday->type);
        $this->assertSame('Sunday', $sunday->title);
    }

    public function test_accepting_removes_future_day_from_active_plan(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);
        $weekBefore = $goal->trainingWeeks()->where('week_number', 2)->firstOrFail()->trainingDays()->count();

        $toolResult = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'remove_day', 'week' => 2, 'day_of_week' => 4],
            ]),
        ]);

        $proposal = CoachProposal::create([
            'agent_message_id' => fake()->uuid(),
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'payload' => $toolResult['payload'],
            'status' => ProposalStatus::Pending,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $week2 = $goal->trainingWeeks()->where('week_number', 2)->firstOrFail();
        $this->assertSame($weekBefore - 1, $week2->trainingDays()->count());
        $this->assertFalse($week2->trainingDays()->where('order', 4)->exists());
    }

    public function test_accepting_updates_existing_day_fields(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        $toolResult = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 2, 'day_of_week' => 4, 'fields' => ['target_km' => 11, 'target_pace_seconds_per_km' => 340]],
            ]),
        ]);

        $proposal = CoachProposal::create([
            'agent_message_id' => fake()->uuid(),
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'payload' => $toolResult['payload'],
            'status' => ProposalStatus::Pending,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $day = $goal->trainingWeeks()->where('week_number', 2)->firstOrFail()
            ->trainingDays()->where('order', 4)->firstOrFail();
        $this->assertEquals(11.0, (float) $day->target_km);
        $this->assertSame(340, $day->target_pace_seconds_per_km);
    }

    public function test_accepting_preserves_past_days_and_days_with_results(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        // Simulate a past-week day by shifting week 1's start back into the past.
        $week1 = $goal->trainingWeeks()->where('week_number', 1)->firstOrFail();
        $week1->starts_at = now()->startOfWeek()->subWeek();
        $week1->save();
        $week1->trainingDays()->update(['date' => $week1->starts_at]);

        $pastCountBefore = $week1->trainingDays()->count();

        $toolResult = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                // Remove everything in week 1 according to the payload
                ['op' => 'remove_day', 'week' => 1, 'day_of_week' => 2],
                ['op' => 'remove_day', 'week' => 1, 'day_of_week' => 4],
                ['op' => 'remove_day', 'week' => 1, 'day_of_week' => 6],
            ]),
        ]);

        $proposal = CoachProposal::create([
            'agent_message_id' => fake()->uuid(),
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'payload' => $toolResult['payload'],
            'status' => ProposalStatus::Pending,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        // Past days should NOT be deleted even though payload says they're gone.
        $this->assertSame($pastCountBefore, $week1->trainingDays()->count());
    }

    public function test_accepting_updates_goal_metadata(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);
        $originalName = $goal->name;

        $toolResult = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'set_goal', 'fields' => ['goal_name' => 'Renamed Race', 'goal_time_seconds' => 2700]],
            ]),
        ]);

        $proposal = CoachProposal::create([
            'agent_message_id' => fake()->uuid(),
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'payload' => $toolResult['payload'],
            'status' => ProposalStatus::Pending,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $goal->refresh();
        $this->assertSame('Renamed Race', $goal->name);
        $this->assertNotSame($originalName, $goal->name);
        $this->assertSame(2700, $goal->goal_time_seconds);
    }
}
