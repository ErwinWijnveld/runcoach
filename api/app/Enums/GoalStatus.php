<?php

namespace App\Enums;

enum GoalStatus: string
{
    case Planning = 'planning';
    case Active = 'active';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
