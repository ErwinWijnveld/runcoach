<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Runner's self-identified ability level (set during onboarding,
 * persistent on users.runner_level). Drives agent communication tone
 * only — has no effect on plan content. The 5 UI tiers collapse to
 * 3 `RunnerToneBucket` cases via `toneBucket()`.
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
