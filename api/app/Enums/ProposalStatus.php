<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum ProposalStatus: string
{
    use HasValues;

    case Pending = 'pending';
    case Accepted = 'accepted';
    case Rejected = 'rejected';
}
