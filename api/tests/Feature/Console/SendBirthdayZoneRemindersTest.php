<?php

namespace Tests\Feature\Console;

use App\Models\User;
use App\Notifications\BirthdayZoneCheckReminder;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class SendBirthdayZoneRemindersTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_sends_to_users_whose_birthday_is_today(): void
    {
        Notification::fake();

        $today = now('Europe/Amsterdam');

        // Should match: same month + day, different year (35 ago).
        $birthday = User::factory()->create([
            'date_of_birth' => $today->copy()->subYears(35)->toDateString(),
        ]);

        // Should NOT match: different month/day.
        $other = User::factory()->create([
            'date_of_birth' => $today->copy()->subYears(35)->addDays(1)->toDateString(),
        ]);

        // Should NOT match: no DOB.
        $noDob = User::factory()->create(['date_of_birth' => null]);

        $this->artisan('plan:remind-birthday')->assertSuccessful();

        Notification::assertSentTo($birthday, BirthdayZoneCheckReminder::class);
        Notification::assertNotSentTo($other, BirthdayZoneCheckReminder::class);
        Notification::assertNotSentTo($noDob, BirthdayZoneCheckReminder::class);
    }

    public function test_skips_user_born_today(): void
    {
        // A user whose `date_of_birth` IS the current date (would be a
        // newborn) shouldn't receive a "happy birthday" push — guards
        // against test fixtures + edge cases.
        Notification::fake();

        $tz = 'Europe/Amsterdam';
        $newborn = User::factory()->create([
            'date_of_birth' => now($tz)->toDateString(),
        ]);

        $this->artisan('plan:remind-birthday')->assertSuccessful();

        Notification::assertNotSentTo($newborn, BirthdayZoneCheckReminder::class);
    }

    public function test_date_override_targets_a_different_day(): void
    {
        // The `--date=` flag lets ops trigger reminders for a specific
        // day (replay missed runs, manual testing).
        Notification::fake();

        $target = '2026-12-15';
        $user = User::factory()->create([
            'date_of_birth' => '1990-12-15',
        ]);
        $unrelated = User::factory()->create([
            'date_of_birth' => '1990-06-21',
        ]);

        $this->artisan('plan:remind-birthday', ['--date' => $target])
            ->assertSuccessful();

        Notification::assertSentTo($user, BirthdayZoneCheckReminder::class);
        Notification::assertNotSentTo($unrelated, BirthdayZoneCheckReminder::class);
    }

    public function test_no_users_with_birthday_today_completes_quietly(): void
    {
        Notification::fake();

        // No users at all → command still exits successfully.
        $this->artisan('plan:remind-birthday')->assertSuccessful();

        Notification::assertNothingSent();
    }
}
