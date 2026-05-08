<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * How realistic the runner's stated goal is given their current fitness
 * snapshot. Drives (a) volume cranking in the builder (more aggressive
 * peak for ambitious goals) and (b) a coach-warning the OnboardingAgent
 * surfaces in its reply.
 */
enum AmbitionLevel: string
{
    use HasValues;

    /** Goal is achievable at the planned pace; no warning needed. */
    case Realistic = 'realistic';

    /** Goal is a stretch but defensible with focused training. */
    case Ambitious = 'ambitious';

    /** Goal is unlikely without much more time, volume, or both. */
    case VeryAmbitious = 'very_ambitious';
}
