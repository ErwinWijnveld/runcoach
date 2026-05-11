<?php

namespace App\Support\Onboarding;

use App\Enums\AmbitionLevel;

/**
 * Five-tier "post-bias" view of plan ambition. Computed from
 * `AmbitionLevel` + `IntensityBias` via `applyBias()`. Each case carries
 * the three knob values that `TrainingPlanBuilder` consumes:
 * peak-volume multiplier, week-over-week growth cap, and quality pace
 * ramp gain. The Conservative floor and AllIn ceiling are reachable
 * only via slider bias; without a bias, only Realistic / Ambitious /
 * VeryAmbitious appear.
 */
enum EffectiveAmbitionLevel: string
{
    case Conservative = 'conservative';
    case Realistic = 'realistic';
    case Ambitious = 'ambitious';
    case VeryAmbitious = 'very_ambitious';
    case AllIn = 'all_in';

    public function peakVolumeMultiplier(): float
    {
        return match ($this) {
            self::Conservative => 1.45,
            self::Realistic => 1.60,
            self::Ambitious => 1.70,
            self::VeryAmbitious => 1.80,
            self::AllIn => 1.95,
        };
    }

    public function weeklyGrowthRatio(): float
    {
        return match ($this) {
            self::Conservative => 1.22,
            self::Realistic => 1.27,
            self::Ambitious => 1.30,
            self::VeryAmbitious => 1.33,
            self::AllIn => 1.36,
        };
    }

    public function qualityPaceRampGain(): float
    {
        return match ($this) {
            self::Conservative => 0.85,
            self::Realistic => 0.92,
            self::Ambitious => 1.00,
            self::VeryAmbitious => 1.10,
            self::AllIn => 1.20,
        };
    }

    public static function shiftFrom(AmbitionLevel $base, int $shift): self
    {
        $ordered = [
            self::Conservative,
            self::Realistic,
            self::Ambitious,
            self::VeryAmbitious,
            self::AllIn,
        ];

        $baseIndex = match ($base) {
            AmbitionLevel::Realistic => 1,
            AmbitionLevel::Ambitious => 2,
            AmbitionLevel::VeryAmbitious => 3,
        };

        return $ordered[max(0, min(4, $baseIndex + $shift))];
    }

    public static function fromAmbitionLevel(AmbitionLevel $level): self
    {
        return self::shiftFrom($level, 0);
    }
}
