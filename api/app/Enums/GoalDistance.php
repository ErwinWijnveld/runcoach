<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum GoalDistance: string
{
    use HasValues;

    case FiveK = '5k';
    case TenK = '10k';
    case HalfMarathon = 'half_marathon';
    case Marathon = 'marathon';
    case Custom = 'custom';
}
