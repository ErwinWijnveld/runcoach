<?php

namespace Tests\Feature\Console\Subscriptions;

use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GrantCompSubscriptionTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_grant_comp_by_email_makes_user_pro(): void
    {
        $user = User::factory()->create(['email' => 'reviewer@example.com']);

        $this->artisan('subscriptions:grant-comp', [
            'user' => 'reviewer@example.com',
            'until' => '+1 year',
        ])->assertSuccessful();

        $user->refresh();
        $this->assertTrue($user->isPro());
        $this->assertSame('comp', $user->pro_product_id);

        $sub = Subscription::where('user_id', $user->id)->firstOrFail();
        $this->assertSame(Subscription::STORE_COMP, $sub->store);
        $this->assertSame('comp', $sub->environment);
        $this->assertSame(Subscription::STATUS_ACTIVE, $sub->status);
    }

    public function test_grant_comp_by_id_works(): void
    {
        $user = User::factory()->create();

        $this->artisan('subscriptions:grant-comp', [
            'user' => (string) $user->id,
            'until' => '+30 days',
        ])->assertSuccessful();

        $user->refresh();
        $this->assertTrue($user->isPro());
    }

    public function test_grant_comp_rejects_past_date(): void
    {
        $user = User::factory()->nonPro()->create();

        $this->artisan('subscriptions:grant-comp', [
            'user' => (string) $user->id,
            'until' => '-1 day',
        ])->assertFailed();

        $user->refresh();
        $this->assertFalse($user->isPro());
        $this->assertDatabaseCount('subscriptions', 0);
    }

    public function test_revoke_clears_pro_state(): void
    {
        $user = User::factory()->create([
            'pro_active_until' => now()->addYear(),
            'pro_product_id' => 'comp',
        ]);
        Subscription::create([
            'user_id' => $user->id,
            'rc_app_user_id' => (string) $user->id,
            'product_id' => 'comp',
            'store' => Subscription::STORE_COMP,
            'status' => Subscription::STATUS_ACTIVE,
            'period_type' => 'comp',
            'purchased_at' => now(),
            'expires_at' => now()->addYear(),
            'environment' => 'comp',
        ]);

        $this->artisan('subscriptions:revoke', ['user' => $user->email])->assertSuccessful();

        $user->refresh();
        $this->assertFalse($user->isPro());
        $this->assertNull($user->pro_active_until);
    }
}
