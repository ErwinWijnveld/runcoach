<?php

namespace App\Jobs\Subscription;

use App\Models\RevenueCatWebhookEvent;
use App\Models\Subscription;
use App\Models\User;
use App\Services\Subscription\EntitlementSyncService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Process one RC webhook delivery, idempotently. Re-runs on the same event row
 * are no-ops (gated on `processed_at`). Errors leave `processed_at` null and
 * set `error`; Laravel retries this job per the backoff table below.
 */
class ProcessRevenueCatWebhookEvent implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    /** @var array<int, int> */
    public array $backoff = [10, 30, 60, 300, 900];

    public function __construct(public int $eventId) {}

    public function handle(EntitlementSyncService $sync): void
    {
        /** @var RevenueCatWebhookEvent|null $row */
        $row = RevenueCatWebhookEvent::find($this->eventId);
        if ($row === null) {
            Log::warning('[rc:webhook] event row missing on job execute', [
                'event_id' => $this->eventId,
            ]);

            return;
        }

        if ($row->processed_at !== null) {
            return; // idempotent retry guard
        }

        $event = $row->payload['event'] ?? null;
        if (! is_array($event) || empty($event['type'])) {
            $this->markProcessed($row, error: 'malformed event payload');

            return;
        }

        $type = (string) $event['type'];
        $user = $this->resolveUser($event);

        // Some event types don't require a user (TEST). For everything else we
        // need one or there's nothing to do.
        if ($user === null && $type !== 'TEST' && $type !== 'TRANSFER') {
            Log::warning('[rc:webhook] no user for event', [
                'event_id' => $row->event_id,
                'event_type' => $type,
                'app_user_id' => $event['app_user_id'] ?? null,
            ]);
            $this->markProcessed($row);

            return;
        }

        match ($type) {
            'INITIAL_PURCHASE',
            'RENEWAL',
            'PRODUCT_CHANGE',
            'UNCANCELLATION',
            'NON_RENEWING_PURCHASE' => $sync->activateFromWebhookEvent($user, $event),

            'CANCELLATION' => $this->handleCancellation($sync, $user, $event),

            'EXPIRATION' => $sync->expire($user),

            'BILLING_ISSUE' => $sync->setStatus($user, Subscription::STATUS_IN_BILLING_RETRY),

            'SUBSCRIPTION_PAUSED' => $sync->setStatus($user, Subscription::STATUS_PAUSED),

            'TRANSFER' => $this->handleTransfer($event),

            'TEST' => null,

            default => Log::warning('[rc:webhook] unknown event type', [
                'event_id' => $row->event_id,
                'event_type' => $type,
            ]),
        };

        $this->markProcessed($row);
    }

    public function failed(Throwable $e): void
    {
        Log::error('[rc:webhook] processing failed', [
            'event_id' => $this->eventId,
            'message' => $e->getMessage(),
        ]);

        RevenueCatWebhookEvent::where('id', $this->eventId)
            ->update(['error' => substr($e->getMessage(), 0, 65000)]);

        report($e);
    }

    /**
     * @param  array<string, mixed>  $event
     */
    private function resolveUser(array $event): ?User
    {
        $primary = $event['app_user_id'] ?? null;
        if ($primary !== null) {
            $user = User::find((int) $primary);
            if ($user !== null) {
                return $user;
            }
        }

        $original = $event['original_app_user_id'] ?? null;
        if ($original !== null) {
            $user = User::find((int) $original);
            if ($user !== null) {
                return $user;
            }
        }

        return null;
    }

    /**
     * CANCELLATION carries a `cancel_reason` enum:
     *   UNSUBSCRIBE | BILLING_ERROR | CUSTOMER_SUPPORT | DEVELOPER_INITIATED |
     *   PRICE_INCREASE | REFUND | TRANSFER | UNKNOWN
     *
     * For REFUND, Apple has clawed back the money — entitlement revokes
     * immediately. Everything else just records cancelled_at; the user keeps
     * access until expires_at and EXPIRATION will fire later.
     *
     * @param  array<string, mixed>  $event
     */
    private function handleCancellation(EntitlementSyncService $sync, User $user, array $event): void
    {
        $reason = strtoupper((string) ($event['cancel_reason'] ?? ''));

        if ($reason === 'REFUND') {
            $sync->revokeRefund($user);

            return;
        }

        $sync->markCancelledKeepingAccess($user);
    }

    /**
     * Update the existing Subscription row's `rc_app_user_id` (and the user
     * link) when an Apple ID transfer rebinds an RC profile to a new app user.
     *
     * @param  array<string, mixed>  $event
     */
    private function handleTransfer(array $event): void
    {
        $from = $event['transferred_from'] ?? [];
        $to = $event['transferred_to'] ?? [];

        if (! is_array($from) || ! is_array($to) || empty($from) || empty($to)) {
            return;
        }

        $sub = Subscription::whereIn('rc_app_user_id', array_map('strval', $from))->first();
        if ($sub === null) {
            return;
        }

        $newAppUserId = (string) $to[0];
        $newUser = User::find((int) $newAppUserId);
        if ($newUser === null) {
            Log::warning('[rc:webhook] TRANSFER target user not found', [
                'to_app_user_id' => $newAppUserId,
            ]);

            return;
        }

        $sub->update([
            'user_id' => $newUser->id,
            'rc_app_user_id' => $newAppUserId,
            'rc_original_app_user_id' => $sub->rc_app_user_id,
        ]);
    }

    private function markProcessed(RevenueCatWebhookEvent $row, ?string $error = null): void
    {
        $row->update([
            'processed_at' => now(),
            'error' => $error,
        ]);
    }
}
