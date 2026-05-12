<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\AmbitionLevel;
use App\Support\Onboarding\AmbitionAssessment;
use App\Support\Onboarding\EffectiveAmbitionLevel;
use PHPUnit\Framework\TestCase;

class AmbitionAssessmentFeasibilityPayloadTest extends TestCase
{
    public function test_returns_null_when_no_pace_gap(): void
    {
        $assessment = AmbitionAssessment::realistic();

        $this->assertNull($assessment->toFeasibilityPayload());
    }

    public function test_ok_zone_for_modest_pace_gap_and_full_volume(): void
    {
        // Needs 10 sec/km/month — under the 12 sec/km realistic baseline.
        // pace_pct = round(min(1, 12/10) * 100) = 100 (clamped)
        // volume_pct = round(0.88 * 100) = 88
        // feasibility = round((1.0 * 0.6 + 0.88 * 0.4) * 100) = 95
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 10.0,
            volumeRatio: 0.88,
            paceGap: 31,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertNotNull($payload);
        $this->assertSame(95, $payload['feasibility_pct']);
        $this->assertSame(100, $payload['pace_score_pct']);
        $this->assertSame(88, $payload['volume_score_pct']);
        $this->assertSame('ok', $payload['verdict_zone']);
        $this->assertSame(31, $payload['pace_gap_seconds_per_km']);
        $this->assertSame(10, $payload['required_improvement_per_month_seconds']);
    }

    public function test_stretch_zone_for_double_required_rate(): void
    {
        // 24 sec/km/month required (2× baseline). Volume 80%.
        // pace_pct = round(12/24 * 100) = 50
        // volume_pct = 80
        // feasibility = round((0.5 * 0.6 + 0.8 * 0.4) * 100) = 62
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 24.0,
            volumeRatio: 0.80,
            paceGap: 60,
            level: AmbitionLevel::Ambitious,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(62, $payload['feasibility_pct']);
        $this->assertSame('stretch', $payload['verdict_zone']);
    }

    public function test_unrealistic_zone_below_forty_percent(): void
    {
        // 38 sec/km/month required (3× baseline). Volume 50%.
        // pace_pct = round(12/38 * 100) = 32
        // volume_pct = 50
        // feasibility = round((0.32 * 0.6 + 0.5 * 0.4) * 100)
        //             = round((0.1894... + 0.20) * 100) = round(38.9) = 39
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 38.0,
            volumeRatio: 0.50,
            paceGap: 114,
            level: AmbitionLevel::VeryAmbitious,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(39, $payload['feasibility_pct']);
        $this->assertSame('unrealistic', $payload['verdict_zone']);
    }

    public function test_null_volume_ratio_clamps_to_full_volume_feasibility(): void
    {
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 12.0,
            volumeRatio: null,
            paceGap: 20,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(100, $payload['volume_score_pct']);
        $this->assertSame(100, $payload['pace_score_pct']);
        $this->assertSame(100, $payload['feasibility_pct']);
    }

    public function test_zone_boundary_70_is_ok(): void
    {
        // pace 1.0 (improvement 12), vol 0.25:
        // (1.0 * 0.6 + 0.25 * 0.4) = 0.70 → 70 → ok (>= 70)
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 12.0,
            volumeRatio: 0.25,
            paceGap: 12,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(70, $payload['feasibility_pct']);
        $this->assertSame('ok', $payload['verdict_zone']);
    }

    public function test_zone_boundary_40_is_stretch(): void
    {
        // pace 0.4 (improvement 30), vol 0.4:
        // (0.4 * 0.6 + 0.4 * 0.4) = 0.40 → 40 → stretch (>= 40)
        $assessment = $this->assessment(
            improvementPerMonthSeconds: 30.0,
            volumeRatio: 0.40,
            paceGap: 90,
        );

        $payload = $assessment->toFeasibilityPayload();

        $this->assertSame(40, $payload['feasibility_pct']);
        $this->assertSame('stretch', $payload['verdict_zone']);
    }

    public function test_adjust_prefill_present_on_every_zone(): void
    {
        foreach (['ok' => [10.0, 0.9, 30], 'stretch' => [24.0, 0.6, 60], 'unrealistic' => [38.0, 0.5, 114]] as $zone => [$rate, $vol, $gap]) {
            $payload = $this->assessment(
                improvementPerMonthSeconds: $rate,
                volumeRatio: $vol,
                paceGap: $gap,
            )->toFeasibilityPayload();

            $this->assertSame($zone, $payload['verdict_zone'], "expected zone {$zone} for rate {$rate}");
            $this->assertIsString($payload['adjust_prefill']);
            $this->assertNotEmpty($payload['adjust_prefill']);
            $this->assertIsString($payload['verdict_label']);
            $this->assertIsString($payload['detail']);
        }
    }

    private function assessment(
        float $improvementPerMonthSeconds,
        ?float $volumeRatio,
        int $paceGap,
        AmbitionLevel $level = AmbitionLevel::Realistic,
    ): AmbitionAssessment {
        return new AmbitionAssessment(
            level: $level,
            paceGapSecondsPerKm: $paceGap,
            improvementPerMonthSeconds: $improvementPerMonthSeconds,
            volumeRatio: $volumeRatio,
            peakVolumeMultiplier: 1.6,
            weeksExtension: 0,
            summary: null,
            suggestion: null,
            effectiveLevel: EffectiveAmbitionLevel::Realistic,
            weeklyGrowthRatio: 1.30,
            qualityPaceRampGain: 1.0,
        );
    }
}
