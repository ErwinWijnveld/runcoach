<?php

namespace App\Models;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use Database\Factories\OrganizationMembershipFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

#[Fillable([
    'organization_id', 'user_id', 'role', 'status',
    'coach_user_id', 'invited_by_user_id', 'invite_token', 'invite_email',
    'invited_at', 'requested_at', 'joined_at', 'removed_at',
])]
class OrganizationMembership extends Model
{
    /** @use HasFactory<OrganizationMembershipFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'role' => OrganizationRole::class,
            'status' => MembershipStatus::class,
            'invited_at' => 'datetime',
            'requested_at' => 'datetime',
            'joined_at' => 'datetime',
            'removed_at' => 'datetime',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Goals owned by this membership's user. Useful when editing a client's
     * training plan from the coach panel.
     */
    public function goals(): HasMany
    {
        return $this->hasMany(Goal::class, 'user_id', 'user_id');
    }

    public function wearableActivities(): HasMany
    {
        return $this->hasMany(WearableActivity::class, 'user_id', 'user_id');
    }

    public function coach(): BelongsTo
    {
        return $this->belongsTo(User::class, 'coach_user_id');
    }

    public function invitedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'invited_by_user_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', MembershipStatus::Active);
    }

    public function scopeInvited(Builder $query): Builder
    {
        return $query->where('status', MembershipStatus::Invited);
    }

    public function scopeRequested(Builder $query): Builder
    {
        return $query->where('status', MembershipStatus::Requested);
    }

    public function isActive(): bool
    {
        return $this->status === MembershipStatus::Active;
    }

    public function isInvited(): bool
    {
        return $this->status === MembershipStatus::Invited;
    }

    public function isRequested(): bool
    {
        return $this->status === MembershipStatus::Requested;
    }

    public function isClient(): bool
    {
        return $this->role === OrganizationRole::Client;
    }

    public function isCoach(): bool
    {
        return $this->role === OrganizationRole::Coach;
    }

    public function isOrgAdmin(): bool
    {
        return $this->role === OrganizationRole::OrgAdmin;
    }

    public static function generateInviteToken(): string
    {
        return Str::random(40);
    }
}
