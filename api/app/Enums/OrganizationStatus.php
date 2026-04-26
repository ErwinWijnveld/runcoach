<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum OrganizationStatus: string
{
    use HasValues;

    case Active = 'active';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match ($this) {
            self::Active => 'Active',
            self::Suspended => 'Suspended',
        };
    }
}
