<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum GoalType: string
{
    use HasValues;

    case Race = 'race';
    case GeneralFitness = 'general_fitness';
    case PrAttempt = 'pr_attempt';
}
