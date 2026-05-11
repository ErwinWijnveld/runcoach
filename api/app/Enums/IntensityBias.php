<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * The runner's own bias on top of the auto-detected ambition. Captured
 * during onboarding as a 3-position slider; persisted on
 * `users.intensity_bias`. Consumed by `AmbitionAssessment::applyBias()`
 * to shift the effective level ±1 within the extended 5-tier table.
 */
enum IntensityBias: string
{
    use HasValues;

    case TakeItEasy = 'take_it_easy';
    case Standard = 'standard';
    case PushMeHarder = 'push_me_harder';
}
