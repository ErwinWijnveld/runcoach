<?php

namespace Tests\Feature\Http;

use App\Enums\GoalStatus;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Carbon;
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

    public function test_accept_pace_adjustment_shifts_upcoming_easy_days_and_preserves_race_day(): void
    {
        Carbon::setTestNow('2026-05-04'); // Monday

        [$user, $goal, $week] = $this->activeGoalWithWeek('2026-06-15');

        // Past easy day with a result — must NOT be touched.
        $past = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'date' => '2026-04-30',
            'target_pace_seconds_per_km' => 360,
        ]);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        TrainingResult::factory()->create([
            'training_day_id' => $past->id,
            'wearable_activity_id' => $activity->id,
        ]);

        // Upcoming easy + tempo + race day.
        $upcomingEasy = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'date' => '2026-05-08',
            'target_pace_seconds_per_km' => 360,
        ]);
        $upcomingTempo = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'tempo',
            'date' => '2026-05-09',
            'target_pace_seconds_per_km' => 300,
        ]);
        $raceDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'date' => '2026-06-15', // matches goal.target_date
            'target_pace_seconds_per_km' => 280,
        ]);

        $notification = UserNotification::factory()->create([
            'user_id' => $user->id,
            'action_data' => [
                'source_training_result_id' => null,
                'training_type' => 'easy',
                'pace_factor' => 1.10,
            ],
        ]);

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/accept")
            ->assertOk();

        $this->assertSame(UserNotification::STATUS_ACCEPTED, $notification->fresh()->status);
        $this->assertSame(360, $past->fresh()->target_pace_seconds_per_km, 'past day untouched');
        $this->assertSame(396, $upcomingEasy->fresh()->target_pace_seconds_per_km, 'upcoming easy shifted by factor');
        $this->assertSame(300, $upcomingTempo->fresh()->target_pace_seconds_per_km, 'tempo of different type untouched');
        $this->assertSame(280, $raceDay->fresh()->target_pace_seconds_per_km, 'race day preserved');
    }

    public function test_dismiss_marks_status_without_touching_schedule(): void
    {
        [$user, $goal, $week] = $this->activeGoalWithWeek('2026-06-15');

        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'date' => now()->addDays(7),
            'target_pace_seconds_per_km' => 360,
        ]);

        $notification = UserNotification::factory()->create([
            'user_id' => $user->id,
            'action_data' => ['training_type' => 'easy', 'pace_factor' => 1.10],
        ]);

        $this->actingAs($user)
            ->postJson("/api/v1/notifications/{$notification->id}/dismiss")
            ->assertOk();

        $this->assertSame(UserNotification::STATUS_DISMISSED, $notification->fresh()->status);
        $this->assertSame(360, $day->fresh()->target_pace_seconds_per_km);
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
    private function activeGoalWithWeek(string $targetDate): array
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
