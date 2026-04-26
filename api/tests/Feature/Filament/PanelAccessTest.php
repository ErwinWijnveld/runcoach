<?php

namespace Tests\Feature\Filament;

use App\Filament\Resources\Organizations\OrganizationResource;
use App\Models\OrganizationMembership;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class PanelAccessTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_admin_panel_access_for_superadmin(): void
    {
        $superadmin = User::factory()->create(['is_superadmin' => true]);
        $regular = User::factory()->create(['is_superadmin' => false]);

        $admin = Filament::getPanel('admin');

        $this->assertTrue($superadmin->canAccessPanel($admin));
        $this->assertFalse($regular->canAccessPanel($admin));
    }

    public function test_coach_panel_access_for_org_admin_and_coach(): void
    {
        $coach = Filament::getPanel('coach');

        $orgAdmin = User::factory()->create();
        OrganizationMembership::factory()->orgAdmin()->for($orgAdmin)->create();

        $coachUser = User::factory()->create();
        OrganizationMembership::factory()->coach()->for($coachUser)->create();

        $client = User::factory()->create();
        OrganizationMembership::factory()->client()->for($client)->create();

        $solo = User::factory()->create();

        $this->assertTrue($orgAdmin->refresh()->canAccessPanel($coach));
        $this->assertTrue($coachUser->refresh()->canAccessPanel($coach));
        $this->assertFalse($client->refresh()->canAccessPanel($coach));
        $this->assertFalse($solo->canAccessPanel($coach));
    }

    public function test_organization_resource_only_visible_to_superadmin(): void
    {
        // Resource::canAccess uses auth()->user()
        $superadmin = User::factory()->create(['is_superadmin' => true]);
        $this->actingAs($superadmin);
        $this->assertTrue(OrganizationResource::canAccess());

        $regular = User::factory()->create();
        $this->actingAs($regular);
        $this->assertFalse(OrganizationResource::canAccess());
    }
}
