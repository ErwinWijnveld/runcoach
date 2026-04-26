<?php

namespace Tests\Feature;

use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class OrganizationMembershipPolicyTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_org_admin_can_view_and_update_anyone_in_their_org(): void
    {
        $org = Organization::factory()->create();
        $admin = User::factory()->create();
        OrganizationMembership::factory()->orgAdmin()->for($org)->for($admin)->create();
        $admin->refresh();

        $clientMembership = OrganizationMembership::factory()->client()->for($org)->create();

        $this->assertTrue($admin->can('view', $clientMembership));
        $this->assertTrue($admin->can('update', $clientMembership));
        $this->assertTrue($admin->can('delete', $clientMembership));
    }

    public function test_coach_can_only_edit_assigned_clients(): void
    {
        $org = Organization::factory()->create();
        $coach = User::factory()->create();
        OrganizationMembership::factory()->coach()->for($org)->for($coach)->create();
        $coach->refresh();

        $assigned = OrganizationMembership::factory()->client()->for($org)->create(['coach_user_id' => $coach->id]);
        $unassigned = OrganizationMembership::factory()->client()->for($org)->create();

        $this->assertTrue($coach->can('view', $assigned));
        $this->assertTrue($coach->can('view', $unassigned));
        $this->assertTrue($coach->can('update', $assigned));
        $this->assertFalse($coach->can('update', $unassigned));
    }

    public function test_user_cannot_see_other_orgs_data(): void
    {
        $orgA = Organization::factory()->create();
        $orgB = Organization::factory()->create();

        $admin = User::factory()->create();
        OrganizationMembership::factory()->orgAdmin()->for($orgA)->for($admin)->create();
        $admin->refresh();

        $foreignClient = OrganizationMembership::factory()->client()->for($orgB)->create();

        $this->assertFalse($admin->can('view', $foreignClient));
        $this->assertFalse($admin->can('update', $foreignClient));
    }

    public function test_org_admin_cannot_delete_themselves(): void
    {
        $org = Organization::factory()->create();
        $admin = User::factory()->create();
        $adminMembership = OrganizationMembership::factory()
            ->orgAdmin()
            ->for($org)
            ->for($admin)
            ->create();

        $admin->refresh();
        $this->assertFalse($admin->can('delete', $adminMembership));
    }

    public function test_coach_cannot_delete_anyone(): void
    {
        $org = Organization::factory()->create();
        $coach = User::factory()->create();
        OrganizationMembership::factory()->coach()->for($org)->for($coach)->create();
        $coach->refresh();

        $client = OrganizationMembership::factory()->client()->for($org)->create(['coach_user_id' => $coach->id]);

        $this->assertFalse($coach->can('delete', $client));
    }

    public function test_superadmin_can_do_everything(): void
    {
        $superadmin = User::factory()->create(['is_superadmin' => true]);
        $foreign = OrganizationMembership::factory()->client()->create();

        $this->assertTrue($superadmin->can('view', $foreign));
        $this->assertTrue($superadmin->can('update', $foreign));
        $this->assertTrue($superadmin->can('delete', $foreign));
    }
}
