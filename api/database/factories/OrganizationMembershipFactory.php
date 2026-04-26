<?php

namespace Database\Factories;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<OrganizationMembership>
 */
class OrganizationMembershipFactory extends Factory
{
    public function definition(): array
    {
        return [
            'organization_id' => Organization::factory(),
            'user_id' => User::factory(),
            'role' => OrganizationRole::Client,
            'status' => MembershipStatus::Active,
            'joined_at' => now(),
        ];
    }

    public function client(): static
    {
        return $this->state(fn () => ['role' => OrganizationRole::Client]);
    }

    public function coach(): static
    {
        return $this->state(fn () => ['role' => OrganizationRole::Coach]);
    }

    public function orgAdmin(): static
    {
        return $this->state(fn () => ['role' => OrganizationRole::OrgAdmin]);
    }

    public function invited(?string $email = null): static
    {
        return $this->state(fn () => [
            'user_id' => null,
            'status' => MembershipStatus::Invited,
            'invite_token' => OrganizationMembership::generateInviteToken(),
            'invite_email' => $email ?? fake()->unique()->safeEmail(),
            'invited_at' => now(),
            'joined_at' => null,
        ]);
    }

    public function requested(): static
    {
        return $this->state(fn () => [
            'status' => MembershipStatus::Requested,
            'requested_at' => now(),
            'joined_at' => null,
        ]);
    }

    public function removed(): static
    {
        return $this->state(fn () => [
            'status' => MembershipStatus::Removed,
            'removed_at' => now(),
        ]);
    }
}
