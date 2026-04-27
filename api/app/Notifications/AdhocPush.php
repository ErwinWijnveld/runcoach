<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

/**
 * Ad-hoc push for ops/admin use — drives the `push:send` artisan command.
 * Don't dispatch this from app code; use a dedicated typed notification
 * (PlanGenerationCompleted, TrainingDayReminder, …) so taps deep-link
 * correctly via PushService.routeFromPayload.
 */
class AdhocPush extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public string $titleText,
        public string $bodyText,
    ) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return [ApnChannel::class];
    }

    public function toApn(object $notifiable): ApnMessage
    {
        return ApnMessage::create()
            ->title($this->titleText)
            ->body($this->bodyText)
            ->sound('default')
            ->expiresAt(now()->addHours(4)->toDateTime())
            ->custom('type', 'adhoc');
    }
}
