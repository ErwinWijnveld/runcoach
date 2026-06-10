<?php

namespace App\Notifications;

use App\Models\TrainingDay;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

class TrainingDayReminder extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public int $trainingDayId) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return [ApnChannel::class];
    }

    public function toApn(object $notifiable): ApnMessage
    {
        $day = TrainingDay::find($this->trainingDayId);

        $title = self::title($day);
        $body = self::body($day);

        return ApnMessage::create()
            ->title($title)
            ->body($body)
            ->sound('default')
            ->expiresAt(now()->addHours(12)->toDateTime())
            ->custom('type', 'training_day_reminder')
            ->custom('training_day_id', $this->trainingDayId);
    }

    public static function title(?TrainingDay $day): string
    {
        if ($day === null) {
            return __('notifications.training_day.fallback_title');
        }

        // target_km can be null (derived from an emptied interval blueprint)
        // — drop the km rather than rendering "Today: 0 km Intervals".
        if ($day->target_km === null || (float) $day->target_km <= 0) {
            return __('notifications.training_day.title_without_km', [
                'type' => $day->type->label(),
            ]);
        }

        return __('notifications.training_day.title_with_km', [
            'km' => self::formatKm((float) $day->target_km),
            'type' => $day->type->label(),
        ]);
    }

    public static function body(?TrainingDay $day): string
    {
        if ($day === null) {
            return __('notifications.training_day.fallback_body');
        }

        $parts = [];

        if (! empty($day->title) && $day->title !== $day->type->label()) {
            $parts[] = $day->title;
        }

        if ($day->target_pace_seconds_per_km !== null) {
            $parts[] = __('notifications.training_day.target_pace', [
                'pace' => self::formatPace($day->target_pace_seconds_per_km),
            ]);
        }

        $parts[] = __('notifications.training_day.tap_for_details');

        return implode('. ', $parts);
    }

    private static function formatKm(float $km): string
    {
        // Strip trailing zeros: 8.0 → "8", 8.5 → "8.5".
        $rounded = round($km, 1);

        return rtrim(rtrim(number_format($rounded, 1, '.', ''), '0'), '.');
    }

    private static function formatPace(int $secondsPerKm): string
    {
        $minutes = intdiv($secondsPerKm, 60);
        $seconds = $secondsPerKm % 60;

        return sprintf('%d:%02d', $minutes, $seconds);
    }
}
