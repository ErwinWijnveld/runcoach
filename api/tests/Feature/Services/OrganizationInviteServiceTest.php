<?php

namespace Tests\Feature\Services;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use App\Notifications\OrganizationInvitation;
use App\Services\OrganizationInviteService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use RuntimeException;
use Tests\TestCase;

class OrganizationInviteServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    private OrganizationInviteService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(OrganizationInviteService::class);
    }

    public function test_invite_creates_pending_membership_with_token_and_sends_mail(): void
    {
        Notification::fake();

        $org = Organization::factory()->create();
        $invitedBy = User::factory()->create();

        $membership = $this->service->invite($org, 'new@example.com', OrganizationRole::Coach, $invitedBy);

        $this->assertNotNull($membership->invite_token);
        $this->assertSame(MembershipStatus::Invited, $membership->status);
        $this->assertSame(OrganizationRole::Coach, $membership->role);
        $this->assertSame('new@example.com', $membership->invite_email);
        $this->assertSame($invitedBy->id, $membership->invited_by_user_id);
        $this->assertNull($membership->user_id);

        Notification::assertSentOnDemand(OrganizationInvitation::class);
    }

    public function test_invite_links_to_existing_user_when_email_matches(): void
    {
        Notification::fake();

        $org = Organization::factory()->create();
        $existing = User::factory()->create(['email' => 'erwin@example.com']);

        $membership = $this->service->invite($org, 'erwin@example.com', OrganizationRole::Client);

        $this->assertSame($existing->id, $membership->user_id);
        Notification::assertSentTo($existing, OrganizationInvitation::class);
    }

    public function test_invite_rejects_duplicate_pending_invite(): void
    {
        Notification::fake();
        $org = Organization::factory()->create();

        $this->service->invite($org, 'dup@example.com', OrganizationRole::Coach);

        $this->expectException(RuntimeException::class);
        $this->service->invite($org, 'dup@example.com', OrganizationRole::Coach);
    }

    public function test_invite_rejects_when_user_already_active_member_elsewhere(): void
    {
        $user = User::factory()->create(['email' => 'active@example.com']);
        OrganizationMembership::factory()
            ->for(Organization::factory())
            ->for($user)
            ->coach()
            ->create();

        $newOrg = Organization::factory()->create();
        $this->expectException(RuntimeException::class);
        $this->service->invite($newOrg, 'active@example.com', OrganizationRole::Coach);
    }

    public function test_accept_activates_invite_and_clears_token(): void
    {
        $org = Organization::factory()->create();
        $user = User::factory()->create(['email' => 'me@example.com']);
        $membership = OrganizationMembership::factory()
            ->for($org)
            ->state(['user_id' => $user->id])
            ->invited('me@example.com')
            ->create();

        $accepted = $this->service->accept($membership, $user);

        $this->assertSame(MembershipStatus::Active, $accepted->status);
        $this->assertNull($accepted->invite_token);
        $this->assertNotNull($accepted->joined_at);
    }

    public function test_accept_rejects_invite_belonging_to_other_user(): void
    {
        $owner = User::factory()->create();
        $membership = OrganizationMembership::factory()
            ->for(Organization::factory())
            ->invited()
            ->create(['user_id' => $owner->id]);

        $intruder = User::factory()->create();

        $this->expectException(RuntimeException::class);
        $this->service->accept($membership, $intruder);
    }

    public function test_reject_marks_membership_removed(): void
    {
        $membership = OrganizationMembership::factory()
            ->for(Organization::factory())
            ->invited()
            ->create();

        $rejected = $this->service->reject($membership);

        $this->assertSame(MembershipStatus::Removed, $rejected->status);
        $this->assertNotNull($rejected->removed_at);
        $this->assertNull($rejected->invite_token);
    }

    public function test_find_by_token_returns_only_pending_invites(): void
    {
        $invited = OrganizationMembership::factory()
            ->for(Organization::factory())
            ->invited()
            ->create();

        $found = $this->service->findByToken($invited->invite_token);
        $this->assertTrue($found->is($invited));
    }

    public function test_invite_assigns_coach_only_for_client_role(): void
    {
        Notification::fake();
        $org = Organization::factory()->create();
        $coach = User::factory()->create();
        OrganizationMembership::factory()->for($org)->for($coach)->coach()->create();

        $clientMembership = $this->service->invite(
            $org,
            'client@example.com',
            OrganizationRole::Client,
            null,
            $coach,
        );
        $this->assertSame($coach->id, $clientMembership->coach_user_id);

        // Coach role should not get coach_user_id (the user IS a coach, not coached by one)
        $coachMembership = $this->service->invite(
            $org,
            'coach@example.com',
            OrganizationRole::Coach,
            null,
            $coach,
        );
        $this->assertNull($coachMembership->coach_user_id);
    }
}
