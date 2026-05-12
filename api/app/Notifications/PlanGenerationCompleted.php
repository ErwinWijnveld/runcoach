<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

class PlanGenerationCompleted extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $conversationId) {}

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
            ->title(__('notifications.plan_generation.completed.title'))
            ->body(__('notifications.plan_generation.completed.body'))
            ->sound('default')
            ->expiresAt(now()->addHours(4)->toDateTime())
            ->custom('type', 'plan_generation_completed')
            ->custom('conversation_id', $this->conversationId);
    }
}
