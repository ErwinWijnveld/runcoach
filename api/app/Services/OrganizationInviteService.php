<?php

namespace App\Services;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use App\Notifications\OrganizationInvitation;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;
use RuntimeException;

class OrganizationInviteService
{
    /**
     * Create an invite for someone to join the org as the given role. If a
     * matching user already exists they get an in-app invite; otherwise we
     * record an email-token invite that turns into an active membership
     * once they create their account.
     */
    public function invite(
        Organization $organization,
        string $email,
        OrganizationRole $role,
        ?User $invitedBy = null,
        ?User $coach = null,
    ): OrganizationMembership {
        $email = Str::lower(trim($email));

        return DB::transaction(function () use ($organization, $email, $role, $invitedBy, $coach) {
            $existingUser = User::where('email', $email)->first();

            $this->guardAgainstDuplicateInvite($organization, $email, $existingUser);

            if ($existingUser) {
                $this->guardAgainstActiveMembership($existingUser);
            }

            $membership = OrganizationMembership::create([
                'organization_id' => $organization->id,
                'user_id' => $existingUser?->id,
                'role' => $role,
                'status' => MembershipStatus::Invited,
                'coach_user_id' => $role === OrganizationRole::Client ? $coach?->id : null,
                'invited_by_user_id' => $invitedBy?->id,
                'invite_token' => OrganizationMembership::generateInviteToken(),
                'invite_email' => $email,
                'invited_at' => now(),
            ]);

            $this->sendInviteNotification($membership, $existingUser);

            return $membership;
        });
    }

    public function accept(OrganizationMembership $membership, User $user): OrganizationMembership
    {
        if (! $membership->isInvited()) {
            throw new RuntimeException('Invite is no longer pending.');
        }

        if ($membership->user_id !== null && $membership->user_id !== $user->id) {
            throw new RuntimeException('This invite belongs to another account.');
        }

        $this->guardAgainstActiveMembership($user);

        $membership->update([
            'user_id' => $user->id,
            'status' => MembershipStatus::Active,
            'joined_at' => now(),
            'invite_token' => null,
        ]);

        return $membership;
    }

    public function reject(OrganizationMembership $membership): OrganizationMembership
    {
        if (! $membership->isInvited()) {
            throw new RuntimeException('Invite is no longer pending.');
        }

        $membership->update([
            'status' => MembershipStatus::Removed,
            'removed_at' => now(),
            'invite_token' => null,
        ]);

        return $membership;
    }

    public function findByToken(string $token): OrganizationMembership
    {
        return OrganizationMembership::where('invite_token', $token)
            ->where('status', MembershipStatus::Invited)
            ->firstOrFail();
    }

    private function guardAgainstDuplicateInvite(Organization $organization, string $email, ?User $user): void
    {
        $exists = OrganizationMembership::query()
            ->where('organization_id', $organization->id)
            ->whereIn('status', [MembershipStatus::Invited, MembershipStatus::Active])
            ->where(function ($q) use ($email, $user) {
                $q->where('invite_email', $email);
                if ($user) {
                    $q->orWhere('user_id', $user->id);
                }
            })
            ->exists();

        if ($exists) {
            throw new RuntimeException("{$email} is already invited to or a member of this organization.");
        }
    }

    private function guardAgainstActiveMembership(User $user): void
    {
        if ($user->memberships()->where('status', MembershipStatus::Active)->exists()) {
            throw new RuntimeException("{$user->email} is already an active member of an organization.");
        }
    }

    private function sendInviteNotification(OrganizationMembership $membership, ?User $existingUser): void
    {
        if ($existingUser) {
            $existingUser->notify(new OrganizationInvitation($membership));

            return;
        }

        try {
            Notification::route('mail', $membership->invite_email)
                ->notify(new OrganizationInvitation($membership));
        } catch (ModelNotFoundException) {
            // Mail driver may be unset in some envs; swallow silently.
        }
    }
}
