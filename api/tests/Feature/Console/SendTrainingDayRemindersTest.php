<?php

namespace Tests\Feature\Console;

use App\Enums\GoalStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Notifications\TrainingDayReminder;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class SendTrainingDayRemindersTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function userWithDayOn(string $date, GoalStatus $goalStatus = GoalStatus::Active): array
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->for($user)->create(['status' => $goalStatus]);
        $week = TrainingWeek::factory()->for($goal)->create();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => $date,
            'type' => TrainingType::Easy,
            'title' => 'Easy',
            'target_km' => 6.0,
            'target_pace_seconds_per_km' => 330,
        ]);

        return [$user, $day];
    }

    public function test_sends_reminder_to_user_with_active_goal_and_today_day(): void
    {
        Notification::fake();

        $today = now(config('app.reminder_timezone'))->toDateString();
        [$user, $day] = $this->userWithDayOn($today);

        $this->artisan('plan:remind-today')->assertSuccessful();

        Notification::assertSentTo(
            $user,
            TrainingDayReminder::class,
            fn (TrainingDayReminder $n) => $n->trainingDayId === $day->id,
        );
    }

    public function test_skips_users_without_an_active_goal(): void
    {
        Notification::fake();

        $today = now(config('app.reminder_timezone'))->toDateString();
        [$user] = $this->userWithDayOn($today, GoalStatus::Completed);

        $this->artisan('plan:remind-today')->assertSuccessful();

        Notification::assertNotSentTo($user, TrainingDayReminder::class);
    }

    public function test_skips_days_that_already_have_a_training_result(): void
    {
        Notification::fake();

        $today = now(config('app.reminder_timezone'))->toDateString();
        [$user, $day] = $this->userWithDayOn($today);
        TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $this->artisan('plan:remind-today')->assertSuccessful();

        Notification::assertNotSentTo($user, TrainingDayReminder::class);
    }

    public function test_does_not_send_for_other_dates(): void
    {
        Notification::fake();

        $tomorrow = now(config('app.reminder_timezone'))->addDay()->toDateString();
        [$user] = $this->userWithDayOn($tomorrow);

        $this->artisan('plan:remind-today')->assertSuccessful();

        Notification::assertNotSentTo($user, TrainingDayReminder::class);
    }

    public function test_date_option_overrides_today(): void
    {
        Notification::fake();

        $tomorrow = now(config('app.reminder_timezone'))->addDay()->toDateString();
        [$user] = $this->userWithDayOn($tomorrow);

        $this->artisan('plan:remind-today', ['--date' => $tomorrow])->assertSuccessful();

        Notification::assertSentTo($user, TrainingDayReminder::class);
    }

    public function test_scheduled_to_run_daily(): void
    {
        $events = collect(app(Schedule::class)->events());
        $reminderEvent = $events->first(
            fn ($e) => str_contains($e->command ?? '', 'plan:remind-today')
        );

        $this->assertNotNull($reminderEvent, 'plan:remind-today must be on the schedule');
        $this->assertSame('0 7 * * *', $reminderEvent->expression);
        $this->assertSame(config('app.reminder_timezone'), $reminderEvent->timezone);
    }
}
