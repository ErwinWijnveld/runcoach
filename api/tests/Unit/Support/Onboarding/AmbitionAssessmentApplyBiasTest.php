<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Enums\IntensityBias;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class AmbitionAssessmentApplyBiasTest extends TestCase
{
    public function test_standard_bias_is_identity(): void
    {
        $original = $this->ambitious();
        $biased = $original->applyBias(IntensityBias::Standard);

        $this->assertSame($original->level, $biased->level);
        $this->assertSame($original->effectiveLevel, $biased->effectiveLevel);
        $this->assertSame($original->peakVolumeMultiplier, $biased->peakVolumeMultiplier);
        $this->assertSame($original->weeklyGrowthRatio, $biased->weeklyGrowthRatio);
        $this->assertSame($original->qualityPaceRampGain, $biased->qualityPaceRampGain);
    }

    public function test_take_it_easy_on_realistic_yields_conservative(): void
    {
        $assessment = AmbitionAssessment::realistic()->applyBias(IntensityBias::TakeItEasy);

        $this->assertSame(AmbitionLevel::Realistic, $assessment->level);
        $this->assertSame(EffectiveAmbitionLevel::Conservative, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.45, $assessment->peakVolumeMultiplier, 0.001);
        $this->assertEqualsWithDelta(1.22, $assessment->weeklyGrowthRatio, 0.001);
        $this->assertEqualsWithDelta(0.85, $assessment->qualityPaceRampGain, 0.001);
    }

    public function test_push_me_harder_on_very_ambitious_yields_all_in(): void
    {
        $assessment = $this->veryAmbitious()->applyBias(IntensityBias::PushMeHarder);

        $this->assertSame(AmbitionLevel::VeryAmbitious, $assessment->level);
        $this->assertSame(EffectiveAmbitionLevel::AllIn, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.95, $assessment->peakVolumeMultiplier, 0.001);
        $this->assertEqualsWithDelta(1.36, $assessment->weeklyGrowthRatio, 0.001);
        $this->assertEqualsWithDelta(1.20, $assessment->qualityPaceRampGain, 0.001);
    }

    public function test_take_it_easy_on_very_ambitious_yields_ambitious(): void
    {
        $assessment = $this->veryAmbitious()->applyBias(IntensityBias::TakeItEasy);

        $this->assertSame(EffectiveAmbitionLevel::Ambitious, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(1.70, $assessment->peakVolumeMultiplier, 0.001);
    }

    public function test_apply_bias_preserves_weeks_extension(): void
    {
        $assessment = $this->ambitious()
            ->withWeeksExtension(4)
            ->applyBias(IntensityBias::PushMeHarder);

        $this->assertSame(4, $assessment->weeksExtension);
    }

    public function test_realistic_factory_carries_effective_level_matching_level(): void
    {
        $assessment = AmbitionAssessment::realistic();

        $this->assertSame(EffectiveAmbitionLevel::Realistic, $assessment->effectiveLevel);
        $this->assertEqualsWithDelta(0.92, $assessment->qualityPaceRampGain, 0.001);
        $this->assertEqualsWithDelta(1.27, $assessment->weeklyGrowthRatio, 0.001);
    }

    private function ambitious(): AmbitionAssessment
    {
        return new AmbitionAssessment(
            level: AmbitionLevel::Ambitious,
            paceGapSecondsPerKm: 50,
            improvementPerMonthSeconds: 15.0,
            volumeRatio: 0.8,
            peakVolumeMultiplier: 1.70,
            weeksExtension: 0,
            summary: 'stretch goal',
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Ambitious,
            weeklyGrowthRatio: 1.30,
            qualityPaceRampGain: 1.00,
        );
    }

    private function veryAmbitious(): AmbitionAssessment
    {
        return new AmbitionAssessment(
            level: AmbitionLevel::VeryAmbitious,
            paceGapSecondsPerKm: 90,
            improvementPerMonthSeconds: 25.0,
            volumeRatio: 0.6,
            peakVolumeMultiplier: 1.80,
            weeksExtension: 0,
            summary: 'big stretch',
            suggestion: 'consider a more conservative goal',
            effectiveLevel: EffectiveAmbitionLevel::VeryAmbitious,
            weeklyGrowthRatio: 1.33,
            qualityPaceRampGain: 1.10,
        );
    }
}
