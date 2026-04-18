<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum GoalStatus: string
{
    use HasValues;

    case Planning = 'planning';
    case Active = 'active';
    case Paused = 'paused';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
