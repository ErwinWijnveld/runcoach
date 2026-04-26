<?php

namespace Tests\Feature;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class OrganizationMembershipTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_user_active_membership_returns_active_row_only(): void
    {
        $user = User::factory()->create();
        $org = Organization::factory()->create();

        OrganizationMembership::factory()->for($org)->for($user)->removed()->create();
        $active = OrganizationMembership::factory()->for($org)->for($user)->coach()->create();

        $this->assertTrue($user->refresh()->activeMembership->is($active));
    }

    public function test_user_pending_invites_and_requests_relationships(): void
    {
        $user = User::factory()->create();
        $org = Organization::factory()->create();

        OrganizationMembership::factory()
            ->for($org)
            ->for($user)
            ->state(['status' => MembershipStatus::Invited])
            ->create();

        OrganizationMembership::factory()
            ->for($org)
            ->for($user)
            ->state(['status' => MembershipStatus::Requested])
            ->create();

        $this->assertCount(1, $user->pendingInvites);
        $this->assertCount(1, $user->pendingRequests);
    }

    public function test_role_helpers_reflect_active_membership(): void
    {
        $org = Organization::factory()->create();
        $coach = User::factory()->create();

        OrganizationMembership::factory()->for($org)->for($coach)->coach()->create();

        $this->assertTrue($coach->refresh()->isCoach());
        $this->assertFalse($coach->isOrgAdmin());
        $this->assertFalse($coach->isClient());
    }

    public function test_organization_active_admin_coach_client_relationships_filter_by_role(): void
    {
        $org = Organization::factory()->create();

        OrganizationMembership::factory()->for($org)->orgAdmin()->create();
        OrganizationMembership::factory()->for($org)->coach()->count(2)->create();
        OrganizationMembership::factory()->for($org)->client()->count(3)->create();
        OrganizationMembership::factory()->for($org)->client()->removed()->create();

        $this->assertCount(1, $org->admins);
        $this->assertCount(2, $org->coaches);
        $this->assertCount(3, $org->clients);
    }

    public function test_coached_clients_relationship_only_returns_active_clients(): void
    {
        $org = Organization::factory()->create();
        $coach = User::factory()->create();
        OrganizationMembership::factory()->for($org)->for($coach)->coach()->create();

        OrganizationMembership::factory()
            ->for($org)
            ->client()
            ->state(['coach_user_id' => $coach->id])
            ->count(2)
            ->create();

        OrganizationMembership::factory()
            ->for($org)
            ->client()
            ->removed()
            ->state(['coach_user_id' => $coach->id])
            ->create();

        $this->assertCount(2, $coach->refresh()->coachedClients);
    }

    public function test_invite_factory_state_creates_invite_token_and_no_user(): void
    {
        $org = Organization::factory()->create();
        $invite = OrganizationMembership::factory()
            ->for($org)
            ->invited('jane@example.com')
            ->create();

        $this->assertNull($invite->user_id);
        $this->assertSame(MembershipStatus::Invited, $invite->status);
        $this->assertSame('jane@example.com', $invite->invite_email);
        $this->assertNotNull($invite->invite_token);
        $this->assertNotNull($invite->invited_at);
    }

    public function test_superadmin_passes_admin_panel_check(): void
    {
        $superadmin = User::factory()->create(['is_superadmin' => true]);
        $regular = User::factory()->create(['is_superadmin' => false]);

        $this->assertTrue($superadmin->isSuperadmin());
        $this->assertFalse($regular->isSuperadmin());
    }

    public function test_has_active_org_role_true_only_for_listed_roles(): void
    {
        $org = Organization::factory()->create();
        $coach = User::factory()->create();
        OrganizationMembership::factory()->for($org)->for($coach)->coach()->create();

        $this->assertTrue($coach->refresh()->hasActiveOrgRole([OrganizationRole::Coach]));
        $this->assertTrue($coach->hasActiveOrgRole([OrganizationRole::OrgAdmin, OrganizationRole::Coach]));
        $this->assertFalse($coach->hasActiveOrgRole([OrganizationRole::OrgAdmin]));
        $this->assertFalse($coach->hasActiveOrgRole([OrganizationRole::Client]));
    }
}
