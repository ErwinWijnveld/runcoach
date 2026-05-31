<?php

namespace App\Services\Subscription;

use App\Models\Subscription;
use App\Models\User;
use Carbon\Carbon;

/**
 * Single source of truth for translating an entitlement payload (whether from a
 * RevenueCat webhook event or from the RC REST API) into `subscriptions` +
 * `users.pro_active_until` writes.
 *
 * Used by:
 *   - ProcessRevenueCatWebhookEvent (job)  — receives RC's webhook `event` shape
 *   - SubscriptionsController::sync         — receives RC's REST entitlement shape
 *
 * Both paths converge here so the 24h grace, status mapping, and field writes
 * stay consistent across the two sources.
 */
class EntitlementSyncService
{
    /**
     * Length of the post-`expires_at` grace window during which we still treat
     * the user as Pro. Covers RC webhook delivery delays (documented at 6h+ in
     * known incidents) without giving anyone meaningfully free access.
     */
    public const GRACE = '+1 day';

    /**
     * Apply an active entitlement derived from a webhook event payload.
     *
     * @param  array<string, mixed>  $event  the RC webhook `event` block
     */
    public function activateFromWebhookEvent(User $user, array $event): void
    {
        $expiresAt = $this->parseTimestamp(
            $event['expiration_at_ms'] ?? null,
            $event['expiration_at'] ?? null,
        );
        $purchasedAt = $this->parseTimestamp(
            $event['purchased_at_ms'] ?? null,
            $event['purchased_at'] ?? null,
        ) ?? now();

        $this->apply($user, [
            'product_id' => (string) ($event['product_id'] ?? 'unknown'),
            'rc_app_user_id' => (string) ($event['app_user_id'] ?? $user->id),
            'rc_original_app_user_id' => isset($event['original_app_user_id'])
                ? (string) $event['original_app_user_id']
                : null,
            'store' => $this->mapStore($event['store'] ?? null),
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => $this->mapPeriodType($event['period_type'] ?? null),
            'purchased_at' => $purchasedAt,
            'expires_at' => $expiresAt,
            'cancelled_at' => null,
            'environment' => strtolower((string) ($event['environment'] ?? 'production')),
            'raw_attributes' => $event,
        ]);
    }

    /**
     * Apply an active entitlement from the RC REST API shape (used by the sync
     * endpoint as defense-in-depth against webhook loss).
     *
     * @param  array<string, mixed>  $entitlement  the `entitlements.pro` block from /v2 customers
     */
    public function activateFromRestEntitlement(User $user, array $entitlement): void
    {
        $expiresAt = $this->parseTimestamp(
            $entitlement['expires_date_ms'] ?? null,
            $entitlement['expires_date'] ?? null,
        );
        $purchasedAt = $this->parseTimestamp(
            $entitlement['purchase_date_ms'] ?? null,
            $entitlement['purchase_date'] ?? null,
        ) ?? now();

        $this->apply($user, [
            'product_id' => (string) ($entitlement['product_identifier'] ?? 'unknown'),
            'rc_app_user_id' => (string) $user->id,
            'rc_original_app_user_id' => null,
            'store' => $this->mapStore($entitlement['store'] ?? null),
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => $this->mapPeriodType($entitlement['period_type'] ?? null),
            'purchased_at' => $purchasedAt,
            'expires_at' => $expiresAt,
            'cancelled_at' => null,
            'environment' => strtolower((string) ($entitlement['environment'] ?? 'production')),
            'raw_attributes' => $entitlement,
        ]);
    }

    /**
     * Mark the user's subscription expired and revoke their entitlement.
     */
    public function expire(User $user): void
    {
        $user->subscription?->update(['status' => Subscription::STATUS_EXPIRED]);
        $user->forceFill([
            'pro_active_until' => null,
            'pro_product_id' => null,
        ])->save();
    }

    /**
     * Mark the user's subscription cancelled (refund flavour) and revoke
     * entitlement immediately — Apple has clawed back the money.
     */
    public function revokeRefund(User $user): void
    {
        $user->subscription?->update([
            'status' => Subscription::STATUS_CANCELLED,
            'cancelled_at' => now(),
        ]);
        $user->forceFill([
            'pro_active_until' => null,
            'pro_product_id' => null,
        ])->save();
    }

    /**
     * Mark cancelled_at without revoking access — user disabled auto-renew but
     * still has paid time remaining.
     */
    public function markCancelledKeepingAccess(User $user): void
    {
        $user->subscription?->update(['cancelled_at' => now()]);
    }

    /**
     * Update subscription status without touching pro_active_until (used for
     * BILLING_ISSUE / SUBSCRIPTION_PAUSED — Apple's grace covers these and RC
     * will extend expires_date if the retry succeeds).
     */
    public function setStatus(User $user, string $status): void
    {
        $user->subscription?->update(['status' => $status]);
    }

    /**
     * Grant an entitlement from a client-side claim (RevenueCat `CustomerInfo`).
     * LOCAL-ENV ONLY — the caller must gate this on `app()->environment('local')`.
     * Lets a Test Store purchase unlock the server-side gate during local dev,
     * where RC's REST API / webhooks don't work with the test key. Defaults to
     * a generous expiry so a short Test Store cycle doesn't expire mid-test.
     */
    public function activateFromClientClaim(User $user, ?string $productId, ?Carbon $expiresAt): void
    {
        $expires = ($expiresAt !== null && $expiresAt->isFuture())
            ? $expiresAt
            : now()->addDays(30);

        $this->apply($user, [
            'product_id' => $productId ?? 'test_store_pro',
            'rc_app_user_id' => (string) $user->id,
            'rc_original_app_user_id' => null,
            'store' => Subscription::STORE_TEST,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now(),
            'expires_at' => $expires,
            'cancelled_at' => null,
            'environment' => 'sandbox',
            'raw_attributes' => ['source' => 'client_claim_local_dev'],
        ]);
    }

    /**
     * Grant a complimentary entitlement (Filament admin action, support comps).
     */
    public function grantComp(User $user, Carbon $until, ?string $note = null): void
    {
        $this->apply($user, [
            'product_id' => 'comp',
            'rc_app_user_id' => (string) $user->id,
            'rc_original_app_user_id' => null,
            'store' => Subscription::STORE_COMP,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'comp',
            'purchased_at' => now(),
            'expires_at' => $until,
            'cancelled_at' => null,
            'environment' => 'comp',
            'raw_attributes' => $note !== null ? ['note' => $note] : null,
        ]);
    }

    /**
     * @param  array<string, mixed>  $attrs  full subscription row attributes (excl. user_id)
     */
    private function apply(User $user, array $attrs): void
    {
        $expiresAt = $attrs['expires_at'] instanceof Carbon ? $attrs['expires_at'] : null;

        Subscription::updateOrCreate(
            ['user_id' => $user->id],
            $attrs,
        );

        $user->forceFill([
            'pro_active_until' => $expiresAt?->copy()->modify(self::GRACE),
            'pro_product_id' => $attrs['product_id'],
        ])->save();
    }

    private function parseTimestamp(mixed $ms, mixed $iso): ?Carbon
    {
        if (is_numeric($ms)) {
            return Carbon::createFromTimestampMs((int) $ms);
        }

        if (is_string($iso) && $iso !== '') {
            return Carbon::parse($iso);
        }

        return null;
    }

    private function mapStore(mixed $store): string
    {
        return match (strtolower((string) $store)) {
            'app_store', 'apple', 'mac_app_store' => Subscription::STORE_APP_STORE,
            'play_store', 'google' => Subscription::STORE_PLAY_STORE,
            'stripe' => Subscription::STORE_STRIPE,
            default => Subscription::STORE_APP_STORE,
        };
    }

    private function mapPeriodType(mixed $periodType): string
    {
        $value = strtolower((string) $periodType);

        return match ($value) {
            'trial' => 'trial',
            'intro' => 'intro',
            'normal' => 'normal',
            default => $value !== '' ? $value : 'normal',
        };
    }
}
