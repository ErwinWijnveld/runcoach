<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum CoachStyle: string
{
    use HasValues;

    case Motivational = 'motivational';
    case Analytical = 'analytical';
    case Balanced = 'balanced';
}
