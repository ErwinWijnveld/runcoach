<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum OrganizationRole: string
{
    use HasValues;

    case OrgAdmin = 'org_admin';
    case Coach = 'coach';
    case Client = 'client';

    public function label(): string
    {
        return match ($this) {
            self::OrgAdmin => 'Org admin',
            self::Coach => 'Coach',
            self::Client => 'Client',
        };
    }
}
