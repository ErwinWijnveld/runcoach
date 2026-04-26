<?php

namespace App\Models;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Enums\OrganizationStatus;
use Database\Factories\OrganizationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'slug', 'description', 'website', 'logo_path', 'status', 'coaches_own_plans'])]
class Organization extends Model
{
    /** @use HasFactory<OrganizationFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'status' => OrganizationStatus::class,
            'coaches_own_plans' => 'boolean',
        ];
    }

    public function memberships(): HasMany
    {
        return $this->hasMany(OrganizationMembership::class);
    }

    public function admins(): HasMany
    {
        return $this->hasMany(OrganizationMembership::class)
            ->where('role', OrganizationRole::OrgAdmin)
            ->where('status', MembershipStatus::Active);
    }

    public function coaches(): HasMany
    {
        return $this->hasMany(OrganizationMembership::class)
            ->where('role', OrganizationRole::Coach)
            ->where('status', MembershipStatus::Active);
    }

    public function clients(): HasMany
    {
        return $this->hasMany(OrganizationMembership::class)
            ->where('role', OrganizationRole::Client)
            ->where('status', MembershipStatus::Active);
    }

    public function pending(): HasMany
    {
        return $this->hasMany(OrganizationMembership::class)
            ->whereIn('status', [MembershipStatus::Invited, MembershipStatus::Requested]);
    }

    public function isActive(): bool
    {
        return $this->status === OrganizationStatus::Active;
    }
}
