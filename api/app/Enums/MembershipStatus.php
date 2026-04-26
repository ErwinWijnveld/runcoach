<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum MembershipStatus: string
{
    use HasValues;

    case Invited = 'invited';
    case Requested = 'requested';
    case Active = 'active';
    case Removed = 'removed';

    public function label(): string
    {
        return match ($this) {
            self::Invited => 'Invited',
            self::Requested => 'Requested',
            self::Active => 'Active',
            self::Removed => 'Removed',
        };
    }
}
