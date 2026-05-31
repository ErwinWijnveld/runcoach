<?php

namespace Tests\Feature\Jobs\Subscription;

use App\Jobs\Subscription\ProcessRevenueCatWebhookEvent;
use App\Models\RevenueCatWebhookEvent;
use App\Models\Subscription;
use App\Models\User;
use App\Services\Subscription\EntitlementSyncService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ProcessRevenueCatWebhookEventTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_initial_purchase_activates_subscription_and_user(): void
    {
        $user = User::factory()->create();
        $expiresAt = now()->addYear()->startOfSecond();

        $row = $this->makeEvent([
            'id' => 'evt-1',
            'type' => 'INITIAL_PURCHASE',
            'app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_yearly',
            'expiration_at_ms' => $expiresAt->getTimestampMs(),
            'purchased_at_ms' => now()->getTimestampMs(),
            'period_type' => 'TRIAL',
            'environment' => 'SANDBOX',
            'store' => 'APP_STORE',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub = Subscription::where('user_id', $user->id)->firstOrFail();
        $this->assertSame(Subscription::STATUS_ACTIVE, $sub->status);
        $this->assertSame('runcoach_pro_yearly', $sub->product_id);
        $this->assertSame('trial', $sub->period_type);
        $this->assertSame('sandbox', $sub->environment);

        $user->refresh();
        $this->assertNotNull($user->pro_active_until);
        // 24h grace baked in.
        $this->assertTrue($user->pro_active_until->greaterThan($expiresAt));
        $this->assertSame('runcoach_pro_yearly', $user->pro_product_id);
        $this->assertTrue($user->isPro());

        $this->assertNotNull($row->fresh()->processed_at);
    }

    public function test_renewal_extends_expires_at(): void
    {
        $user = User::factory()->create();
        Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_monthly',
            'store' => Subscription::STORE_APP_STORE,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now()->subMonth(),
            'expires_at' => now()->addDay(),
            'environment' => 'production',
        ]);

        $newExpiry = now()->addMonth()->startOfSecond();
        $row = $this->makeEvent([
            'id' => 'evt-2',
            'type' => 'RENEWAL',
            'app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_monthly',
            'expiration_at_ms' => $newExpiry->getTimestampMs(),
            'environment' => 'PRODUCTION',
            'period_type' => 'NORMAL',
            'store' => 'APP_STORE',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub = Subscription::where('user_id', $user->id)->firstOrFail();
        $this->assertTrue($sub->expires_at->greaterThanOrEqualTo($newExpiry->subSecond()));
    }

    public function test_cancellation_unsubscribe_preserves_access(): void
    {
        [$user, $sub] = $this->makeActiveUser();
        $proUntilBefore = $user->pro_active_until;

        $row = $this->makeEvent([
            'id' => 'evt-cancel',
            'type' => 'CANCELLATION',
            'app_user_id' => (string) $user->id,
            'cancel_reason' => 'UNSUBSCRIBE',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub->refresh();
        $this->assertNotNull($sub->cancelled_at);
        $user->refresh();
        $this->assertNotNull($user->pro_active_until);
        $this->assertSame((string) $proUntilBefore, (string) $user->pro_active_until);
        $this->assertTrue($user->isPro());
    }

    public function test_cancellation_refund_revokes_immediately(): void
    {
        [$user, $sub] = $this->makeActiveUser();

        $row = $this->makeEvent([
            'id' => 'evt-refund',
            'type' => 'CANCELLATION',
            'app_user_id' => (string) $user->id,
            'cancel_reason' => 'REFUND',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub->refresh();
        $this->assertSame(Subscription::STATUS_CANCELLED, $sub->status);
        $user->refresh();
        $this->assertNull($user->pro_active_until);
        $this->assertNull($user->pro_product_id);
        $this->assertFalse($user->isPro());
    }

    public function test_expiration_revokes(): void
    {
        [$user, $sub] = $this->makeActiveUser();

        $row = $this->makeEvent([
            'id' => 'evt-exp',
            'type' => 'EXPIRATION',
            'app_user_id' => (string) $user->id,
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub->refresh();
        $this->assertSame(Subscription::STATUS_EXPIRED, $sub->status);
        $user->refresh();
        $this->assertNull($user->pro_active_until);
        $this->assertFalse($user->isPro());
    }

    public function test_billing_issue_keeps_access(): void
    {
        [$user, $sub] = $this->makeActiveUser();
        $proUntilBefore = $user->pro_active_until;

        $row = $this->makeEvent([
            'id' => 'evt-billing',
            'type' => 'BILLING_ISSUE',
            'app_user_id' => (string) $user->id,
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $sub->refresh();
        $this->assertSame(Subscription::STATUS_IN_BILLING_RETRY, $sub->status);
        $user->refresh();
        $this->assertSame((string) $proUntilBefore, (string) $user->pro_active_until);
        $this->assertTrue($user->isPro());
    }

    public function test_test_event_is_noop_but_marked_processed(): void
    {
        $row = $this->makeEvent([
            'id' => 'evt-test',
            'type' => 'TEST',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $this->assertNotNull($row->fresh()->processed_at);
        $this->assertDatabaseCount('subscriptions', 0);
    }

    public function test_idempotent_replay_does_nothing(): void
    {
        $user = User::factory()->create();
        $row = $this->makeEvent([
            'id' => 'evt-replay',
            'type' => 'INITIAL_PURCHASE',
            'app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_yearly',
            'expiration_at_ms' => now()->addYear()->getTimestampMs(),
            'environment' => 'PRODUCTION',
            'period_type' => 'NORMAL',
            'store' => 'APP_STORE',
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));
        $user->refresh();
        $afterFirst = $user->pro_active_until;

        // Manually re-run on the same row — should early-return.
        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));
        $user->refresh();

        $this->assertSame((string) $afterFirst, (string) $user->pro_active_until);
        $this->assertDatabaseCount('subscriptions', 1);
    }

    public function test_unknown_event_type_logs_and_acks(): void
    {
        $user = User::factory()->create();
        $row = $this->makeEvent([
            'id' => 'evt-unknown',
            'type' => 'SOME_FUTURE_TYPE',
            'app_user_id' => (string) $user->id,
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $this->assertNotNull($row->fresh()->processed_at);
    }

    public function test_transfer_rebinds_subscription_to_new_user(): void
    {
        $oldUser = User::factory()->create();
        $newUser = User::factory()->create();

        Subscription::create([
            'user_id' => $oldUser->id,
            'rc_app_user_id' => (string) $oldUser->id,
            'product_id' => 'runcoach_pro_yearly',
            'store' => Subscription::STORE_APP_STORE,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now()->subMonth(),
            'expires_at' => now()->addMonths(11),
            'environment' => 'production',
        ]);

        $row = $this->makeEvent([
            'id' => 'evt-transfer',
            'type' => 'TRANSFER',
            'transferred_from' => [(string) $oldUser->id],
            'transferred_to' => [(string) $newUser->id],
        ]);

        (new ProcessRevenueCatWebhookEvent($row->id))->handle(app(EntitlementSyncService::class));

        $this->assertDatabaseHas('subscriptions', [
            'user_id' => $newUser->id,
            'rc_app_user_id' => (string) $newUser->id,
            'rc_original_app_user_id' => (string) $oldUser->id,
        ]);
    }

    /**
     * @param  array<string, mixed>  $event
     */
    private function makeEvent(array $event): RevenueCatWebhookEvent
    {
        return RevenueCatWebhookEvent::create([
            'event_id' => $event['id'],
            'event_type' => $event['type'],
            'app_user_id' => $event['app_user_id'] ?? null,
            'payload' => ['event' => $event],
            'received_at' => now(),
        ]);
    }

    /**
     * @return array{0: User, 1: Subscription}
     */
    private function makeActiveUser(): array
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addMonths(11),
            'pro_product_id' => 'runcoach_pro_yearly',
        ]);
        $sub = Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_yearly',
            'store' => Subscription::STORE_APP_STORE,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now()->subMonth(),
            'expires_at' => now()->addMonths(11)->subDay(),
            'environment' => 'production',
        ]);

        return [$user, $sub];
    }
}
