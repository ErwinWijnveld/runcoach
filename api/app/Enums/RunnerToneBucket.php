<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Three-bucket tone axis the agent prompts branch on. `RunnerLevel`
 * collapses to this via `toneBucket()` — keeping prompt code stable
 * when we tune the 5-tier UI cases.
 */
enum RunnerToneBucket: string
{
    use HasValues;

    case Novice = 'novice';
    case Standard = 'standard';
    case Expert = 'expert';
}
