<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Runner's self-identified ability level (set during onboarding,
 * persistent on users.runner_level). The 5 UI tiers collapse to 3
 * `RunnerToneBucket` cases via `toneBucket()`. Drives two things:
 *   1. Agent communication tone (coach phrasing).
 *   2. Interval-blueprint shape — `RunnerToneBucket::Expert` (Advanced /
 *      SubElite / Elite) gets longer reps (800m → 1000m → 1200m
 *      progression, 600m sharpener). Novice + Standard share the
 *      400m → 800m → 800m progression with a 400m sharpener.
 * Volume curves, cutbacks, taper, and non-interval days are unaffected
 * — those are driven by `IntensityBias` + `PlanAmbitionAnalyzer`.
 */
enum RunnerLevel: string
{
    use HasValues;

    case Beginner = 'beginner';
    case Intermediate = 'intermediate';
    case Advanced = 'advanced';
    case SubElite = 'sub_elite';
    case Elite = 'elite';

    public function toneBucket(): RunnerToneBucket
    {
        return match ($this) {
            self::Beginner => RunnerToneBucket::Novice,
            self::Intermediate => RunnerToneBucket::Standard,
            self::Advanced, self::SubElite, self::Elite => RunnerToneBucket::Expert,
        };
    }
}
