<?php

namespace App\Listeners;

use App\Models\DeviceToken;
use Illuminate\Notifications\Events\NotificationFailed;
use NotificationChannels\Apn\ApnChannel;

class PruneInvalidApnsToken
{
    /**
     * APNs surfaces invalid tokens via `NotificationFailed` with reasons like
     * `Unregistered` (app uninstalled) or `BadDeviceToken` (token never valid
     * for this team). Both mean the row in `device_tokens` is dead — drop it
     * so the next push attempt doesn't hit the same wall.
     *
     * Auto-registered by Laravel 13 listener auto-discovery (event type-hint
     * on handle() — do not register manually in EventServiceProvider).
     */
    public function handle(NotificationFailed $event): void
    {
        if ($event->channel !== ApnChannel::class) {
            return;
        }

        $reason = $event->data['error'] ?? null;
        $token = $event->data['token'] ?? null;

        if (! is_string($token) || $token === '') {
            return;
        }

        if (! in_array($reason, ['Unregistered', 'BadDeviceToken'], true)) {
            return;
        }

        DeviceToken::where('token', $token)->delete();
    }
}
