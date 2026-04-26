<?php

namespace App\Policies;

use App\Enums\OrganizationRole;
use App\Models\OrganizationMembership;
use App\Models\User;

class OrganizationMembershipPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSuperadmin() || $user->isOrgAdmin() || $user->isCoach();
    }

    public function view(User $user, OrganizationMembership $membership): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        if ($user->organizationId() !== $membership->organization_id) {
            return false;
        }

        if ($user->isOrgAdmin()) {
            return true;
        }

        if ($user->isCoach() && $membership->role === OrganizationRole::Client) {
            return true;
        }

        return $membership->user_id === $user->id;
    }

    public function create(User $user): bool
    {
        return $user->isSuperadmin() || $user->isOrgAdmin() || $user->isCoach();
    }

    public function update(User $user, OrganizationMembership $membership): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        if ($user->organizationId() !== $membership->organization_id) {
            return false;
        }

        if ($user->isOrgAdmin()) {
            return true;
        }

        if ($user->isCoach() && $membership->role === OrganizationRole::Client) {
            return $membership->coach_user_id === $user->id;
        }

        return false;
    }

    public function delete(User $user, OrganizationMembership $membership): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        if ($user->organizationId() !== $membership->organization_id) {
            return false;
        }

        if (! $user->isOrgAdmin()) {
            return false;
        }

        return $membership->user_id !== $user->id;
    }

    public function assignCoach(User $user, OrganizationMembership $membership): bool
    {
        if ($membership->role !== OrganizationRole::Client) {
            return false;
        }

        return $this->update($user, $membership);
    }
}
