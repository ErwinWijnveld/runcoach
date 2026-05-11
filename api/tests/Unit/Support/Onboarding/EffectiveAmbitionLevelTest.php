<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class EffectiveAmbitionLevelTest extends TestCase
{
    public function test_shift_from_realistic_minus_one_yields_conservative(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Conservative,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, -1),
        );
    }

    public function test_shift_from_realistic_zero_yields_realistic(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Realistic,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, 0),
        );
    }

    public function test_shift_from_realistic_plus_one_yields_ambitious(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Ambitious,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, 1),
        );
    }

    public function test_shift_from_very_ambitious_plus_one_clamps_to_all_in(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::AllIn,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::VeryAmbitious, 1),
        );
    }

    public function test_shift_from_realistic_minus_two_clamps_to_conservative(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Conservative,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::Realistic, -2),
        );
    }

    public function test_shift_from_very_ambitious_plus_three_clamps_to_all_in(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::AllIn,
            EffectiveAmbitionLevel::shiftFrom(AmbitionLevel::VeryAmbitious, 3),
        );
    }

    public function test_from_ambition_level_is_zero_shift(): void
    {
        $this->assertSame(
            EffectiveAmbitionLevel::Realistic,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::Realistic),
        );
        $this->assertSame(
            EffectiveAmbitionLevel::Ambitious,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::Ambitious),
        );
        $this->assertSame(
            EffectiveAmbitionLevel::VeryAmbitious,
            EffectiveAmbitionLevel::fromAmbitionLevel(AmbitionLevel::VeryAmbitious),
        );
    }

    public function test_peak_volume_multipliers_match_tier_table(): void
    {
        $this->assertEqualsWithDelta(1.45, EffectiveAmbitionLevel::Conservative->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.60, EffectiveAmbitionLevel::Realistic->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.70, EffectiveAmbitionLevel::Ambitious->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.80, EffectiveAmbitionLevel::VeryAmbitious->peakVolumeMultiplier(), 0.001);
        $this->assertEqualsWithDelta(1.95, EffectiveAmbitionLevel::AllIn->peakVolumeMultiplier(), 0.001);
    }

    public function test_weekly_growth_ratios_match_tier_table(): void
    {
        $this->assertEqualsWithDelta(1.22, EffectiveAmbitionLevel::Conservative->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.27, EffectiveAmbitionLevel::Realistic->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.30, EffectiveAmbitionLevel::Ambitious->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.33, EffectiveAmbitionLevel::VeryAmbitious->weeklyGrowthRatio(), 0.001);
        $this->assertEqualsWithDelta(1.36, EffectiveAmbitionLevel::AllIn->weeklyGrowthRatio(), 0.001);
    }

    public function test_quality_pace_ramp_gain_matches_tier_table(): void
    {
        $this->assertEqualsWithDelta(0.85, EffectiveAmbitionLevel::Conservative->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(0.92, EffectiveAmbitionLevel::Realistic->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.00, EffectiveAmbitionLevel::Ambitious->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.10, EffectiveAmbitionLevel::VeryAmbitious->qualityPaceRampGain(), 0.001);
        $this->assertEqualsWithDelta(1.20, EffectiveAmbitionLevel::AllIn->qualityPaceRampGain(), 0.001);
    }
}
