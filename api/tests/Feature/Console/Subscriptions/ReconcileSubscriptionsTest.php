<?php

namespace Tests\Feature\Console\Subscriptions;

use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class ReconcileSubscriptionsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_expires_subscriptions_past_grace(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->subDays(2),
            'pro_product_id' => 'runcoach_pro_monthly',
        ]);
        Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_monthly',
            'store' => Subscription::STORE_APP_STORE,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now()->subMonth(),
            'expires_at' => now()->subDays(3), // past 24h grace
            'environment' => 'production',
        ]);

        $this->artisan('subscriptions:reconcile')->assertSuccessful();

        $sub = Subscription::where('user_id', $user->id)->firstOrFail();
        $this->assertSame(Subscription::STATUS_EXPIRED, $sub->status);
        $user->refresh();
        $this->assertNull($user->pro_active_until);
        $this->assertNull($user->pro_product_id);
    }

    public function test_skips_comp_subscriptions(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addYears(5),
            'pro_product_id' => 'comp',
        ]);
        Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'comp',
            'store' => Subscription::STORE_COMP,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'comp',
            'purchased_at' => now()->subYear(),
            'expires_at' => now()->subDays(3), // expired, but comp
            'environment' => 'comp',
        ]);

        $this->artisan('subscriptions:reconcile')->assertSuccessful();

        $user->refresh();
        $this->assertNotNull($user->pro_active_until); // untouched
        $sub = Subscription::where('user_id', $user->id)->firstOrFail();
        $this->assertSame(Subscription::STATUS_ACTIVE, $sub->status);
    }

    public function test_overdue_active_logs_warning_and_still_expires(): void
    {
        Log::spy();

        $user = User::factory()->create([
            'pro_active_until' => now()->subDays(10),
        ]);
        Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'runcoach_pro_monthly',
            'store' => Subscription::STORE_APP_STORE,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'normal',
            'purchased_at' => now()->subMonths(2),
            'expires_at' => now()->subDays(10), // active and >7d overdue
            'environment' => 'production',
        ]);

        $this->artisan('subscriptions:reconcile')->assertSuccessful();

        Log::shouldHaveReceived('warning')
            ->atLeast()->once()
            ->withArgs(fn ($message) => str_contains((string) $message, 'overdue'));

        // Auto-fix still happens — reconciler is not just a forensic logger.
        $user->refresh();
        $this->assertNull($user->pro_active_until);
    }
}
