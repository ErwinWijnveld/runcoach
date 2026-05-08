<?php

namespace Tests\Feature\Services\Onboarding;

use App\Enums\PaceConfidence;
use App\Enums\PaceDerivation;
use App\Enums\TrainingType;
use App\Models\User;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Support\Onboarding\FitnessSnapshot;
use App\Support\Onboarding\OnboardingFormInput;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingPlanBuilderTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function snapshot(
        ?int $threshold = 300,
        ?int $easy = 360,
        ?int $vo2max = 270,
        float $weeklyKm = 25.0,
        bool $hasIntensity = true,
    ): FitnessSnapshot {
        return new FitnessSnapshot(
            thresholdPaceSecondsPerKm: $threshold,
            easyPaceSecondsPerKm: $easy,
            vo2maxPaceSecondsPerKm: $vo2max,
            confidence: PaceConfidence::Medium,
            derivation: PaceDerivation::HrZonePace,
            weeklyKmRecent4Weeks: $weeklyKm,
            weeklyRunsRecent4Weeks: 4.0,
            longestRunRecent8Weeks: 12.0,
            maxHeartRate: 190,
            hasIntensityHistory: $hasIntensity,
        );
    }

    private function form(array $overrides = []): OnboardingFormInput
    {
        return OnboardingFormInput::fromArray(array_merge([
            'goal_type' => 'race',
            'goal_name' => 'Test Race',
            'distance_meters' => 10000,
            'target_date' => now()->addWeeks(8)->toDateString(),
            'goal_time_seconds' => 3000,
            'days_per_week' => 4,
            'preferred_weekdays' => [2, 4, 6, 7],
            'coach_style' => 'balanced',
        ], $overrides));
    }

    public function test_two_days_per_week_emits_quality_plus_long_in_build_weeks(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form(['days_per_week' => 2, 'preferred_weekdays' => [3, 7]]),
        );

        // Find a build week (not race week, not taper).
        $buildWeek = collect($payload['schedule']['weeks'])
            ->first(fn (array $w) => count($w['days']) === 2 && $w['week_number'] <= 3);

        $this->assertNotNull($buildWeek, 'should have a build week with 2 days');

        $types = array_map(fn ($d) => $d['type'], $buildWeek['days']);
        $this->assertContains(TrainingType::LongRun->value, $types, 'every build week needs a long run');

        // Quality alternates between intervals (odd weeks) and tempo
        // (even weeks). Either is acceptable here.
        $hasQuality = in_array(TrainingType::Interval->value, $types, true)
            || in_array(TrainingType::Tempo->value, $types, true);
        $this->assertTrue($hasQuality, '2-day plan should ship a quality session, not just easy');
    }

    public function test_three_days_per_week_includes_quality_session(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form(['days_per_week' => 3, 'preferred_weekdays' => [2, 4, 7]]),
        );

        // First build week: should have quality (intervals on odd weeks).
        $week1 = $payload['schedule']['weeks'][0];
        $types = array_map(fn ($d) => $d['type'], $week1['days']);
        $this->assertContains(TrainingType::LongRun->value, $types);

        $hasQuality = in_array(TrainingType::Interval->value, $types, true)
            || in_array(TrainingType::Tempo->value, $types, true);
        $this->assertTrue($hasQuality, '3-day plan must include a quality session');
    }

    public function test_long_run_capped_at_40_percent_of_weekly_volume(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 30.0),
            $this->form(['days_per_week' => 4]),
        );

        foreach ($payload['schedule']['weeks'] as $week) {
            $longRun = collect($week['days'])
                ->firstWhere('type', TrainingType::LongRun->value);
            if (! $longRun) {
                continue;
            }
            $cap = $week['total_km'] * 0.40 + 0.5; // float tolerance
            $this->assertLessThanOrEqual(
                $cap,
                $longRun['target_km'],
                "long run > 40% in week {$week['week_number']} ({$longRun['target_km']}/{$week['total_km']})",
            );
        }
    }

    public function test_race_day_lands_on_target_date(): void
    {
        $target = now()->addWeeks(8)->endOfWeek(); // a Sunday 8 weeks out
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'target_date' => $target->toDateString(),
                'preferred_weekdays' => [2, 4, 6, 7],
            ]),
        );

        $weekStart = now()->startOfWeek();
        $weekIndex = (int) $weekStart->diffInWeeks($target);
        $raceWeek = $payload['schedule']['weeks'][$weekIndex] ?? null;
        $this->assertNotNull($raceWeek);

        $dows = array_map(fn ($d) => $d['day_of_week'], $raceWeek['days']);
        $this->assertContains((int) $target->isoWeekday(), $dows, 'race day must be present');
    }

    public function test_volume_curve_respects_30_percent_growth_cap(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 10.0),
            $this->form([
                'distance_meters' => 21097,
                'target_date' => now()->addWeeks(12)->toDateString(),
                'days_per_week' => 4,
            ]),
        );

        $weeks = $payload['schedule']['weeks'];
        for ($i = 1; $i < count($weeks); $i++) {
            $prev = $weeks[$i - 1]['total_km'];
            $curr = $weeks[$i]['total_km'];
            if ($prev <= 0) {
                continue;
            }
            // Growth cap is 30%; cutbacks/tapers can drop. We only check
            // upward jumps.
            if ($curr > $prev) {
                $ratio = $curr / $prev;
                $this->assertLessThanOrEqual(
                    1.305,
                    $ratio,
                    "week {$weeks[$i]['week_number']} grew {$ratio} from {$weeks[$i - 1]['week_number']}",
                );
            }
        }
    }

    public function test_taper_reduces_volume_in_final_weeks_for_race_goals(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 30.0),
            $this->form([
                'distance_meters' => 42195,
                'target_date' => now()->addWeeks(16)->toDateString(),
                'days_per_week' => 5,
            ]),
        );

        $weeks = $payload['schedule']['weeks'];
        $peakWeek = collect($weeks)->max('total_km');
        $raceWeek = end($weeks);
        $this->assertLessThan(
            $peakWeek * 0.6,
            $raceWeek['total_km'],
            'race week volume should taper at least 40% below peak',
        );
    }

    public function test_no_back_to_back_quality_and_long(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'days_per_week' => 4,
                'preferred_weekdays' => [1, 2, 3, 4, 5, 6, 7],
            ]),
        );

        foreach ($payload['schedule']['weeks'] as $week) {
            $longDow = collect($week['days'])->firstWhere('type', TrainingType::LongRun->value)['day_of_week'] ?? null;
            $qualityDow = collect($week['days'])
                ->whereIn('type', [TrainingType::Interval->value, TrainingType::Tempo->value])
                ->first()['day_of_week'] ?? null;

            if ($longDow !== null && $qualityDow !== null) {
                $cyclic = min(abs($longDow - $qualityDow), 7 - abs($longDow - $qualityDow));
                $this->assertGreaterThan(
                    1,
                    $cyclic,
                    "quality on dow {$qualityDow}, long on dow {$longDow} in week {$week['week_number']} are too close",
                );
            }
        }
    }

    public function test_general_fitness_uses_default_weeks_when_no_target_date(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 15.0),
            OnboardingFormInput::fromArray([
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'balanced',
            ]),
        );

        $this->assertCount(8, $payload['schedule']['weeks']);
        $this->assertNull($payload['target_date']);
    }

    public function test_paces_come_from_snapshot_easy_pace(): void
    {
        $snapshot = $this->snapshot(threshold: 280, easy: 350, vo2max: 250);
        $payload = app(TrainingPlanBuilder::class)->build(
            $snapshot,
            $this->form(['days_per_week' => 4]),
        );

        $easyDays = collect($payload['schedule']['weeks'])
            ->flatMap(fn ($w) => $w['days'])
            ->where('type', TrainingType::Easy->value);

        foreach ($easyDays as $day) {
            $this->assertSame(
                $snapshot->easyPaceSecondsPerKm,
                $day['target_pace_seconds_per_km'],
                'easy pace must equal snapshot.easyPaceSecondsPerKm',
            );
        }
    }

    public function test_intervals_have_warmup_work_recovery_cooldown_shape(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form(['days_per_week' => 4]),
        );

        $intervalDay = collect($payload['schedule']['weeks'])
            ->flatMap(fn ($w) => $w['days'])
            ->firstWhere('type', TrainingType::Interval->value);

        $this->assertNotNull($intervalDay, 'plan must contain at least one interval session');
        $segments = $intervalDay['intervals'] ?? [];
        $this->assertNotEmpty($segments);

        $kinds = array_map(fn ($s) => $s['kind'], $segments);
        $this->assertSame('warmup', $kinds[0]);
        $this->assertSame('cooldown', end($kinds));
        $this->assertContains('work', $kinds);
        $this->assertContains('recovery', $kinds);
    }

    public function test_tempo_pace_ramps_toward_goal_pace_across_plan(): void
    {
        // Threshold 5:30 (330), goal 4:00 (240). 9-week plan, no intensity history.
        // The earlier flat-cap bug clobbered this entire ramp at threshold+5 (335)
        // for low-confidence snapshots. Tempo MUST progress across the build.
        $snapshot = $this->snapshot(
            threshold: 330,
            easy: 360,
            vo2max: 310,
            hasIntensity: false,
        );

        $payload = app(TrainingPlanBuilder::class)->build(
            $snapshot,
            $this->form([
                'distance_meters' => 5000,
                'goal_time_seconds' => 1200, // 4:00/km
                'target_date' => now()->addWeeks(9)->endOfWeek()->toDateString(),
                'days_per_week' => 3,
                'preferred_weekdays' => [1, 2, 4, 5, 7],
            ]),
        );

        $tempoPaces = collect($payload['schedule']['weeks'])
            ->flatMap(fn ($w) => collect($w['days'])->map(fn ($d) => [
                'week' => $w['week_number'],
                'pace' => $d['type'] === TrainingType::Tempo->value
                    ? $d['target_pace_seconds_per_km']
                    : null,
            ])->filter(fn ($x) => $x['pace'] !== null))
            ->values();

        if ($tempoPaces->count() < 2) {
            $this->markTestSkipped('Plan did not include enough tempo days to verify ramp.');
        }

        $earliest = $tempoPaces->first();
        $latest = $tempoPaces->last();

        // Earliest tempo should be slower than the latest one (lower number = faster).
        $this->assertGreaterThan(
            $latest['pace'],
            $earliest['pace'],
            "tempo pace must ramp from slower to faster across the plan; got {$earliest['pace']} → {$latest['pace']}",
        );

        // Earliest tempo must be in early-ramp territory (well slower than
        // threshold pace 330) — guards the regression where a flat-cap
        // collapsed the entire ramp to threshold+5. With the new
        // last-build-week-peaks ramp the very first tempo week sits at
        // ~330-340 depending on which week the alternation lands on.
        $this->assertGreaterThanOrEqual(
            315,
            $earliest['pace'],
            'earliest tempo should start in the slow part of the ramp, not near the endpoint',
        );

        // Latest tempo should be very close to goal pace (240). With the
        // new ramp peaking at the LAST build week, the last tempo lands
        // at goal+5 (245) — the buffer keeps it sustainable.
        $this->assertLessThanOrEqual(
            260,
            $latest['pace'],
            "latest tempo must approach goal pace ({$latest['pace']} should be ≤ 4:20/km)",
        );
        $this->assertGreaterThanOrEqual(
            240,
            $latest['pace'],
            "latest tempo must not be faster than goal pace ({$latest['pace']} vs goal 240)",
        );
    }

    public function test_interval_work_pace_ramps_toward_goal_pace(): void
    {
        $snapshot = $this->snapshot(
            threshold: 330,
            easy: 360,
            vo2max: 310,
            hasIntensity: true,
        );

        $payload = app(TrainingPlanBuilder::class)->build(
            $snapshot,
            $this->form([
                'distance_meters' => 5000,
                'goal_time_seconds' => 1200,
                'target_date' => now()->addWeeks(9)->endOfWeek()->toDateString(),
                'days_per_week' => 4,
                'preferred_weekdays' => [1, 2, 4, 5, 7],
            ]),
        );

        $workPaces = collect($payload['schedule']['weeks'])
            ->flatMap(fn ($w) => $w['days'])
            ->where('type', TrainingType::Interval->value)
            ->flatMap(fn ($d) => $d['intervals'] ?? [])
            ->where('kind', 'work')
            ->pluck('target_pace_seconds_per_km')
            ->filter()
            ->values();

        if ($workPaces->count() < 2) {
            $this->markTestSkipped('Plan did not include enough interval work segments.');
        }

        $first = $workPaces->first();
        $last = $workPaces->last();
        $this->assertGreaterThan($last, $first, 'interval work pace should get faster across the plan');
        $this->assertLessThanOrEqual(260, $last, 'last interval work pace should be near goal pace');
    }

    public function test_ranking_intervals_over_tempo_makes_every_quality_an_interval(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'days_per_week' => 3,
                'preferred_weekdays' => [2, 4, 7],
                'run_type_preferences' => ['interval', 'tempo', 'easy', 'long_run'],
            ]),
        );

        // 3-day plan has [primaryQuality, easy_or_tempo, long]. With
        // intervals ranked above tempo, every BUILD week's primaryQuality
        // slot must be an interval session. Skip cutback / taper / race
        // weeks (they use tempo_short / sharpener regardless of ranking).
        $buildWeeks = collect($payload['schedule']['weeks'])
            ->filter(fn ($w) => ($w['focus'] ?? '') !== 'Recovery / cutback'
                && ($w['focus'] ?? '') !== 'Race week'
                && ($w['focus'] ?? '') !== 'Taper'
                && count($w['days']) === 3)
            ->take(4);

        $this->assertNotEmpty($buildWeeks);
        foreach ($buildWeeks as $week) {
            $hasInterval = collect($week['days'])->contains('type', TrainingType::Interval->value);
            $this->assertTrue(
                $hasInterval,
                "week {$week['week_number']} ({$week['focus']}) must contain an interval session when intervals is ranked over tempo",
            );
        }
    }

    public function test_ranking_tempo_over_intervals_makes_every_quality_a_tempo(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'days_per_week' => 3,
                'run_type_preferences' => ['tempo', 'interval', 'easy', 'long_run'],
            ]),
        );

        $buildWeek = collect($payload['schedule']['weeks'])
            ->first(fn ($w) => count($w['days']) === 3 && ($w['focus'] ?? '') !== 'Race week');

        $this->assertNotNull($buildWeek);
        $hasInterval = collect($buildWeek['days'])->contains('type', TrainingType::Interval->value);
        $hasTempo = collect($buildWeek['days'])->contains('type', TrainingType::Tempo->value);
        $this->assertFalse($hasInterval, 'no interval session expected when tempo ranked above intervals');
        $this->assertTrue($hasTempo, 'tempo session expected when tempo ranked above intervals');
    }

    public function test_ranking_intervals_at_5_days_upgrades_one_easy_to_quality(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'days_per_week' => 5,
                'preferred_weekdays' => [1, 2, 3, 4, 5, 6, 7],
                'run_type_preferences' => ['interval', 'tempo', 'easy', 'long_run'],
            ]),
        );

        // 5-day default = [quality, tempo, easy, easy, long] — one easy
        // gets swapped to a second quality. Expect 2 interval days plus
        // a tempo plus 1 easy plus 1 long.
        $buildWeek = collect($payload['schedule']['weeks'])
            ->first(fn ($w) => count($w['days']) === 5
                && ($w['focus'] ?? '') !== 'Race week'
                && ($w['focus'] ?? '') !== 'Recovery / cutback'
                && ($w['focus'] ?? '') !== 'Taper');

        $this->assertNotNull($buildWeek);
        $intervalCount = collect($buildWeek['days'])->where('type', TrainingType::Interval->value)->count();
        $this->assertGreaterThanOrEqual(2, $intervalCount, 'expected at least 2 interval sessions per week with intervals gold-ranked at 5 days/week');
    }

    public function test_ranking_long_run_at_top_widens_long_run_cap(): void
    {
        // Two plans, identical except long_run rank. The "loved" plan
        // should produce a longer long run on the same week.
        $form = fn (array $prefs) => $this->form([
            'days_per_week' => 4,
            'distance_meters' => 21097,
            'target_date' => now()->addWeeks(12)->endOfWeek()->toDateString(),
            'run_type_preferences' => $prefs,
        ]);

        $loverPayload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 35.0),
            $form(['long_run', 'easy', 'tempo', 'interval']),
        );
        $haterPayload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 35.0),
            $form(['interval', 'tempo', 'easy', 'long_run']),
        );

        $loverPeak = collect($loverPayload['schedule']['weeks'])
            ->flatMap(fn ($w) => $w['days'])
            ->where('type', TrainingType::LongRun->value)
            ->max('target_km');

        $haterPeak = collect($haterPayload['schedule']['weeks'])
            ->flatMap(fn ($w) => $w['days'])
            ->where('type', TrainingType::LongRun->value)
            ->max('target_km');

        $this->assertGreaterThan(
            $haterPeak,
            $loverPeak,
            "long-run lover ({$loverPeak} km) should have longer long runs than long-run hater ({$haterPeak} km)",
        );
    }

    public function test_low_volume_runner_still_gets_long_run_every_week(): void
    {
        // Regression: a runner with a low baseline (~11 km/week, 4 days/week)
        // would previously end up with NO long_run for the first 5 weeks of
        // the plan because the builder produced 4-5 km long runs and the
        // optimizer's old MIN_LONG_RUN_KM=6 threshold demoted them to easy.
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 11.3),
            $this->form([
                'distance_meters' => 5000,
                'target_date' => now()->addWeeks(9)->endOfWeek()->toDateString(),
                'days_per_week' => 4,
                'preferred_weekdays' => [1, 2, 5, 6, 7],
            ]),
        );
        $payload = app(PlanOptimizerService::class)
            ->optimize($payload, User::factory()->create());

        $weeksWithoutLong = collect($payload['schedule']['weeks'])
            ->filter(fn ($w) => ($w['focus'] ?? '') !== 'Race week')
            ->reject(fn ($w) => collect($w['days'])->contains('type', TrainingType::LongRun->value))
            ->pluck('week_number')
            ->all();

        $this->assertEmpty(
            $weeksWithoutLong,
            'low-volume runner should still have a long_run in every non-race week; missing in weeks: '
                .implode(',', $weeksWithoutLong),
        );
    }

    public function test_no_ranking_preserves_default_behaviour(): void
    {
        // Sanity: when run_type_preferences is null, the builder produces
        // the same shape it always did (alternating quality, no upgrades,
        // 0.40 long-run cap).
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(),
            $this->form([
                'days_per_week' => 5,
                'preferred_weekdays' => [1, 2, 3, 4, 5, 6, 7],
            ]),
        );

        $buildWeek = collect($payload['schedule']['weeks'])
            ->first(fn ($w) => count($w['days']) === 5
                && ($w['focus'] ?? '') !== 'Recovery / cutback'
                && ($w['focus'] ?? '') !== 'Race week'
                && ($w['focus'] ?? '') !== 'Taper');

        $this->assertNotNull($buildWeek);
        // Default 5-day shape: 1 long + 1 quality + 1 tempo + 2 easy.
        $intervalCount = collect($buildWeek['days'])->where('type', TrainingType::Interval->value)->count();
        $easyCount = collect($buildWeek['days'])->where('type', TrainingType::Easy->value)->count();
        $this->assertSame(1, $intervalCount, 'default plan should have 1 interval session per build week');
        $this->assertSame(2, $easyCount, 'default plan should have 2 easy sessions per build week');
    }

    public function test_peak_volume_capped_at_1_6x_baseline(): void
    {
        $payload = app(TrainingPlanBuilder::class)->build(
            $this->snapshot(weeklyKm: 10.0),
            $this->form([
                'distance_meters' => 42195,
                'target_date' => now()->addWeeks(16)->toDateString(),
                'days_per_week' => 4,
            ]),
        );

        $peak = collect($payload['schedule']['weeks'])->max('total_km');
        $this->assertLessThanOrEqual(10.0 * 1.6 + 0.1, $peak, 'peak volume should not exceed 1.6× baseline');
    }
}
