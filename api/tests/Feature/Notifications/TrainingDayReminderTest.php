<?php

namespace Tests\Feature\Notifications;

use App\Enums\TrainingType;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Notifications\TrainingDayReminder;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use NotificationChannels\Apn\ApnChannel;
use Tests\TestCase;

class TrainingDayReminderTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_via_targets_apn(): void
    {
        $notification = new TrainingDayReminder(1);

        $this->assertSame([ApnChannel::class], $notification->via(User::factory()->make()));
    }

    public function test_to_apn_renders_title_body_and_payload(): void
    {
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => TrainingType::Easy,
            'title' => 'Easy',
            'target_km' => 8.5,
            'target_pace_seconds_per_km' => 330,
        ]);

        $message = (new TrainingDayReminder($day->id))->toApn(User::factory()->make());

        $this->assertSame('Today: 8.5km Easy', $message->title);
        $this->assertStringContainsString('Target pace 5:30/km', $message->body);
        $this->assertSame('training_day_reminder', $message->custom['type']);
        $this->assertSame($day->id, $message->custom['training_day_id']);
    }

    public function test_renders_whole_km_without_trailing_zero(): void
    {
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => TrainingType::LongRun,
            'title' => 'Long run',
            'target_km' => 20.0,
            'target_pace_seconds_per_km' => 360,
        ]);

        $message = (new TrainingDayReminder($day->id))->toApn(User::factory()->make());

        $this->assertSame('Today: 20km Long run', $message->title);
    }

    public function test_includes_custom_title_when_distinct_from_type_label(): void
    {
        // Race-day pattern: title = goal name (e.g. "Rotterdam Marathon").
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => TrainingType::Tempo,
            'title' => 'Rotterdam Marathon',
            'target_km' => 42.2,
            'target_pace_seconds_per_km' => 300,
        ]);

        $message = (new TrainingDayReminder($day->id))->toApn(User::factory()->make());

        $this->assertStringContainsString('Rotterdam Marathon', $message->body);
    }

    public function test_handles_missing_pace_gracefully(): void
    {
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => TrainingType::Easy,
            'title' => 'Easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => null,
        ]);

        $message = (new TrainingDayReminder($day->id))->toApn(User::factory()->make());

        $this->assertStringNotContainsString('Target pace', $message->body);
        $this->assertStringContainsString('Tap for details', $message->body);
    }
}
