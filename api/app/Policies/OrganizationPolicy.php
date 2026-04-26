<?php

namespace App\Policies;

use App\Models\Organization;
use App\Models\User;

class OrganizationPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isSuperadmin();
    }

    public function view(User $user, Organization $organization): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        return $user->organizationId() === $organization->id;
    }

    public function create(User $user): bool
    {
        return $user->isSuperadmin();
    }

    public function update(User $user, Organization $organization): bool
    {
        if ($user->isSuperadmin()) {
            return true;
        }

        return $user->organizationId() === $organization->id && $user->isOrgAdmin();
    }

    public function delete(User $user, Organization $organization): bool
    {
        return $user->isSuperadmin();
    }

    public function suspend(User $user): bool
    {
        return $user->isSuperadmin();
    }
}
