<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;

/**
 * Yearly birthday push: nudges the runner to verify their HR zones now
 * that their age (and therefore Tanaka-derived max HR) just rolled
 * over by a year. Tap deep-links into the HR zones edit sheet so the
 * user can confirm or recompute in one motion.
 *
 * Dispatched by `App\Console\Commands\SendBirthdayZoneReminders`
 * (`plan:remind-birthday`) which runs daily and finds users whose
 * `date_of_birth` matches today's month + day.
 */
class BirthdayZoneCheckReminder extends Notification implements ShouldQueue
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
            ->title('Happy birthday! 🎂')
            ->body("You're a year wiser — let's refresh your heart-rate zones to match.")
            ->sound('default')
            // Birthday is only relevant on the day itself; expire a few
            // hours after midnight tomorrow if undelivered.
            ->expiresAt(now()->addHours(36)->toDateTime())
            ->custom('type', 'birthday_zone_check');
    }
}
