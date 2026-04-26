<?php

namespace Tests\Feature\Http;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MembershipApiTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_index_returns_users_memberships(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $org = Organization::factory()->create();
        OrganizationMembership::factory()->for($org)->for($user)->coach()->create();

        $response = $this->getJson('/api/v1/me/memberships');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.role', 'coach')
            ->assertJsonPath('data.0.organization.id', $org->id);
    }

    public function test_accept_by_token_activates_invite(): void
    {
        $user = User::factory()->create(['email' => 'me@example.com']);
        Sanctum::actingAs($user);

        $org = Organization::factory()->create();
        $invite = OrganizationMembership::factory()
            ->for($org)
            ->invited('me@example.com')
            ->create();

        $response = $this->postJson("/api/v1/me/memberships/invites/token/{$invite->invite_token}/accept");

        $response->assertOk()
            ->assertJsonPath('membership.status', 'active');

        $this->assertSame(MembershipStatus::Active, $invite->refresh()->status);
        $this->assertSame($user->id, $invite->user_id);
    }

    public function test_accept_in_app_invite_for_existing_user(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $org = Organization::factory()->create();
        $invite = OrganizationMembership::factory()
            ->for($org)
            ->for($user)
            ->state(['status' => MembershipStatus::Invited, 'invited_at' => now()])
            ->create();

        $response = $this->postJson("/api/v1/me/memberships/invites/{$invite->id}/accept");

        $response->assertOk()->assertJsonPath('membership.status', 'active');
    }

    public function test_accept_rejects_other_users_invite(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        Sanctum::actingAs($a);

        $invite = OrganizationMembership::factory()
            ->for(Organization::factory())
            ->invited()
            ->create(['user_id' => $b->id]);

        $this->postJson("/api/v1/me/memberships/invites/{$invite->id}/accept")
            ->assertForbidden();
    }

    public function test_request_to_join_creates_pending_request(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $org = Organization::factory()->create();

        $response = $this->postJson('/api/v1/me/memberships/requests', [
            'organization_id' => $org->id,
        ]);

        $response->assertCreated()
            ->assertJsonPath('membership.status', 'requested');
    }

    public function test_request_blocked_when_user_has_active_membership(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        OrganizationMembership::factory()->for($user)->coach()->create();

        $newOrg = Organization::factory()->create();
        $this->postJson('/api/v1/me/memberships/requests', [
            'organization_id' => $newOrg->id,
        ])->assertStatus(422);
    }

    public function test_duplicate_request_returns_422(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $org = Organization::factory()->create();
        OrganizationMembership::factory()
            ->for($org)
            ->for($user)
            ->state(['status' => MembershipStatus::Requested, 'requested_at' => now(), 'role' => OrganizationRole::Client])
            ->create();

        $this->postJson('/api/v1/me/memberships/requests', [
            'organization_id' => $org->id,
        ])->assertStatus(422);
    }

    public function test_leave_marks_active_membership_removed(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $membership = OrganizationMembership::factory()->for($user)->client()->create();

        $this->postJson('/api/v1/me/memberships/leave')->assertOk();

        $this->assertSame(MembershipStatus::Removed, $membership->refresh()->status);
    }

    public function test_organizations_search_returns_active_orgs(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        Organization::factory()->create(['name' => 'Amsterdam Running Club']);
        Organization::factory()->create(['name' => 'Berlin Striders']);
        Organization::factory()->suspended()->create(['name' => 'Suspended Co']);

        $response = $this->getJson('/api/v1/organizations/search?q=ams');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Amsterdam Running Club');
    }

    public function test_profile_includes_membership_fields(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $membership = OrganizationMembership::factory()->for($user)->client()->create();

        $this->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('user.current_membership.id', $membership->id)
            ->assertJsonPath('user.current_membership.role', 'client')
            ->assertJsonStructure(['user' => ['pending_invites', 'pending_requests']]);
    }
}
