<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

class PlanGenerationFailed extends Notification implements ShouldQueue
{
    use Queueable;

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
            ->title('Plan generation hit a snag')
            ->body('Tap to try again.')
            ->sound('default')
            ->expiresAt(now()->addHours(4)->toDateTime())
            ->custom('type', 'plan_generation_failed');
    }
}
