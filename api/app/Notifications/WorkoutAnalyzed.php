<?php

namespace App\Notifications;

use App\Models\TrainingResult;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

/**
 * Sent after `GenerateActivityFeedback` finishes scoring + writing AI
 * feedback for a freshly synced run that matched a training day. The push
 * is the user's "your run was logged and analyzed" signal — body summarises
 * compliance + km so they get value without opening the app.
 *
 * Tap routing: payload `type=workout_analyzed` + `training_day_id` →
 * Flutter `PushService.routeFromPayload` sends them to the day detail.
 */
class WorkoutAnalyzed extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public int $trainingResultId) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return [ApnChannel::class];
    }

    public function toApn(object $notifiable): ApnMessage
    {
        $result = TrainingResult::with('trainingDay')->find($this->trainingResultId);

        if (! $result) {
            return ApnMessage::create()
                ->title('Workout analyzed')
                ->body('Tap to view your run.')
                ->sound('default')
                ->custom('type', 'workout_analyzed');
        }

        $km = (float) $result->actual_km;
        $compliance = (float) $result->compliance_score;
        $dayLabel = $result->trainingDay?->title ?? 'Run';

        $title = 'Workout analyzed — '.$this->scoreLabel($compliance).'/10';
        $body = sprintf(
            '%s · %skm at %s/km. %s',
            $dayLabel,
            $this->kmLabel($km),
            $this->pace((int) $result->actual_pace_seconds_per_km),
            $this->complianceVerdict($compliance),
        );

        return ApnMessage::create()
            ->title($title)
            ->body($body)
            ->sound('default')
            ->expiresAt(now()->addHours(12)->toDateTime())
            ->custom('type', 'workout_analyzed')
            ->custom('training_day_id', (int) $result->training_day_id)
            ->custom('training_result_id', $result->id)
            ->custom('wearable_activity_id', (int) $result->wearable_activity_id)
            ->custom('compliance_score', round($compliance, 1));
    }

    private function pace(int $seconds): string
    {
        if ($seconds <= 0) {
            return '—';
        }

        return sprintf('%d:%02d', intdiv($seconds, 60), $seconds % 60);
    }

    private function complianceVerdict(float $score): string
    {
        return match (true) {
            $score >= 9.0 => 'Nailed it.',
            $score >= 7.5 => 'Solid execution.',
            $score >= 6.0 => 'Close to plan.',
            $score >= 4.0 => 'Off plan.',
            default => 'Way off plan.',
        };
    }

    private function scoreLabel(float $value): string
    {
        $rounded = round($value, 1);

        return rtrim(rtrim(number_format($rounded, 1, '.', ''), '0'), '.');
    }

    private function kmLabel(float $value): string
    {
        $rounded = round($value, 1);

        return rtrim(rtrim(number_format($rounded, 1, '.', ''), '0'), '.');
    }
}
