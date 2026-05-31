<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

class PlanEvaluationReady extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public int $evaluationId,
        public bool $hasProposal,
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
        $bodyKey = $this->hasProposal
            ? 'notifications.plan_evaluation.body_with_proposal'
            : 'notifications.plan_evaluation.body_no_change';

        return ApnMessage::create()
            ->title(__('notifications.plan_evaluation.title'))
            ->body(__($bodyKey))
            ->sound('default')
            ->expiresAt(now()->addHours(24)->toDateTime())
            ->custom('type', 'plan_evaluation')
            ->custom('evaluation_id', $this->evaluationId);
    }
}
