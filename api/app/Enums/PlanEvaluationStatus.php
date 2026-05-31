<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum PlanEvaluationStatus: string
{
    use HasValues;

    case Pending = 'pending';
    case Processing = 'processing';
    case Ready = 'ready';
    case NoChangeNeeded = 'no_change_needed';
    case Accepted = 'accepted';
    case Dismissed = 'dismissed';
}
