<?php

namespace App\Enums;

enum GoalType: string
{
    case Race = 'race';
    case GeneralFitness = 'general_fitness';
    case PrAttempt = 'pr_attempt';
}
