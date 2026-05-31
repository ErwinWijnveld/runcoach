<?php

namespace Tests\Feature\Filament;

use App\Filament\Resources\Users\Pages\ListUsers;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class UserResourceProActionsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_grant_pro_year_makes_the_user_pro(): void
    {
        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create(['pro_active_until' => null]);
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('grantProYear', $runner);

        $runner->refresh();
        $this->assertTrue($runner->isPro());
        $this->assertSame('comp', $runner->pro_product_id);
        $this->assertTrue($runner->pro_active_until->gt(now()->addMonths(11)));

        $subscription = Subscription::where('user_id', $runner->id)->first();
        $this->assertNotNull($subscription);
        $this->assertSame(Subscription::STATUS_ACTIVE, $subscription->status);
        $this->assertSame(Subscription::STORE_COMP, $subscription->store);
    }

    public function test_grant_pro_month_makes_the_user_pro(): void
    {
        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create(['pro_active_until' => null]);
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('grantProMonth', $runner);

        $runner->refresh();
        $this->assertTrue($runner->isPro());
        $this->assertTrue($runner->pro_active_until->lt(now()->addMonths(2)));
    }

    public function test_revoke_pro_clears_entitlement(): void
    {
        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create(['pro_active_until' => now()->addYear()]);
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('revokePro', $runner);

        $runner->refresh();
        $this->assertFalse($runner->isPro());
        $this->assertNull($runner->pro_active_until);
    }
}
