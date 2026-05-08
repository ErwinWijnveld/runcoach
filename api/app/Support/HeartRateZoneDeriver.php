<?php

namespace App\Support;

use App\Enums\HeartRateZonesSource;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Support\Facades\DB;

/**
 * Computes a five-zone HR table for a user. Industry-standard approach
 * (matches Strava / Polar / Apple defaults; more research-grounded than
 * the empirical-from-training-data path we tried first):
 *
 * 1. **Tanaka** (`208 − 0.7·age`) for max HR — research-backed prior
 *    (Tanaka et al. 2001, ±7 bpm SD across studies).
 * 2. **Karvonen** zone bounds when resting HR is available — adds
 *    HRR back into each bound, individualises for athletes with low
 *    resting HR. (This is what Apple Fitness does since watchOS 10.)
 * 3. **Upward-only empirical correction** — IF the runner has ≥3
 *    qualifying training maxes > Tanaka + UPWARD_CORRECTION_BUFFER
 *    (default 5 bpm), use the median of those top observations. This
 *    catches genuine race-PB efforts where the runner DID hit max,
 *    without letting normal training (where max is rarely reached)
 *    drag the estimate downward. Mirrors Garmin's "auto-detected max
 *    HR" model (only updates upward, never down).
 * 4. **Default** — last-resort untrained-athlete table when no signal
 *    is available. NOT persisted by the controller.
 *
 * What we deliberately don't do (despite tempting): use
 * empirical-as-primary. Recreational runners almost never hit true
 * max in normal training, so observed-max systematically underestimates
 * by 10-20 bpm. No major running app uses observed-max as the primary
 * source — confirmed by 2026 review of Strava / Garmin / Polar /
 * Apple Fitness defaults.
 */
class HeartRateZoneDeriver
{
    /**
     * How far above Tanaka an empirical max needs to be before we trust
     * the runner actually hit a near-max effort. 5 bpm is wider than
     * Tanaka's ~7 bpm SD lower bound, narrow enough that genuine race
     * efforts aren't missed.
     */
    public const UPWARD_CORRECTION_BUFFER = 5;

    /** Need ≥3 qualifying high-effort observations before correcting upward. */
    public const UPWARD_CORRECTION_MIN_SAMPLES = 3;

    public function derive(User $user, ?int $age, ?int $restingHeartRate): DerivationResult
    {
        $age = $this->sanitizeAge($age);
        $restingHeartRate = $this->sanitizeRestingHr($restingHeartRate);

        // No age → can't compute the formula prior. Fall back to defaults
        // and let the user set them manually.
        if ($age === null) {
            return $this->defaultResult();
        }

        $tanakaMax = $this->maxHrFromAge($age);

        // Optional upward correction. Only fires when the runner has at
        // least UPWARD_CORRECTION_MIN_SAMPLES observations above
        // Tanaka + buffer — never overrides downward.
        [$correctedMax, $sampleCount] = $this->maybeApplyUpwardCorrection($user, $tanakaMax);

        $maxHr = $correctedMax ?? $tanakaMax;

        $zones = $restingHeartRate !== null
            ? $this->zonesFromKarvonen($maxHr, $restingHeartRate)
            : $this->zonesFromMaxHr($maxHr);

        return new DerivationResult(
            zones: $zones,
            source: HeartRateZonesSource::DerivedAge,
            maxHeartRate: $maxHr,
            sampleCount: $sampleCount,
            age: $age,
            restingHeartRate: $restingHeartRate,
            wasCorrected: $correctedMax !== null,
        );
    }

    /**
     * Look for ≥3 qualifying max_heartrate readings above Tanaka + buffer.
     * If found, return the median of the top observations. Otherwise null
     * (no correction → use Tanaka as-is).
     *
     * Filters mirror the empirical path for "qualifying run":
     *   - physiological window (100..220 bpm) — kills sensor glitches,
     *   - ≥10 min duration — kills warmups + aborted runs,
     *   - avg HR ≥ 130 — kills "watch on, walking the dog",
     *   - last 365 days — current fitness only,
     *   - running activity types only.
     *
     * @return array{0: int|null, 1: int} [correctedMax, sampleCount]
     */
    private function maybeApplyUpwardCorrection(User $user, int $tanakaMax): array
    {
        $threshold = $tanakaMax + self::UPWARD_CORRECTION_BUFFER;

        $maxes = DB::table('wearable_activities')
            ->where('user_id', $user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereNotNull('max_heartrate')
            ->whereBetween('max_heartrate', [HeartRateZones::MIN_PHYSIO_HR, HeartRateZones::MAX_PHYSIO_HR])
            ->where('max_heartrate', '>=', $threshold)
            ->where('duration_seconds', '>=', HeartRateZones::MIN_DURATION_SEC)
            ->whereNotNull('average_heartrate')
            ->where('average_heartrate', '>=', HeartRateZones::MIN_AVG_HR)
            ->where('start_date', '>=', now()->subDays(HeartRateZones::MAX_LOOKBACK_DAYS))
            ->orderByDesc('max_heartrate')
            ->limit(10)
            ->pluck('max_heartrate')
            ->map(fn ($v): int => (int) round((float) $v))
            ->all();

        if (count($maxes) < self::UPWARD_CORRECTION_MIN_SAMPLES) {
            return [null, count($maxes)];
        }

        // Median of top-3 (or top-5 if available) — robust against a
        // single sensor glitch in the qualifying band.
        $top = array_slice($maxes, 0, max(self::UPWARD_CORRECTION_MIN_SAMPLES, 5));
        $corrected = $this->median($top);

        return [$corrected, count($maxes)];
    }

    /**
     * Tanaka: maxHR ≈ 208 − 0.7·age. Research-standard formula since the
     * 2001 meta-analysis (351 studies, n≈19k). More accurate than
     * 220−age, especially over 40.
     */
    private function maxHrFromAge(int $age): int
    {
        return (int) round(HeartRateZones::TANAKA_INTERCEPT - HeartRateZones::TANAKA_SLOPE * $age);
    }

    /**
     * Standard percent-of-max zones using `ZONE_PCT` (0.60/0.70/0.80/0.90).
     * Matches the Polar default + the existing Flutter UI's math.
     *
     * @return list<array{min:int, max:int}>
     */
    private function zonesFromMaxHr(int $maxHr): array
    {
        $bounds = [];
        foreach (HeartRateZones::ZONE_PCT as $pct) {
            $bounds[] = (int) round($maxHr * $pct);
        }

        return $this->buildZones($bounds);
    }

    /**
     * Karvonen: zone upper bound = restingHR + (pct × HRR). Apple Fitness
     * uses this since watchOS 10 — accounts for resting HR so a fit
     * runner with RHR 45 doesn't get artificially low Z2/Z3.
     *
     * Z1 lower stays 0 (semantic: "everything below endurance"), only
     * the four interior boundaries shift.
     *
     * @return list<array{min:int, max:int}>
     */
    private function zonesFromKarvonen(int $maxHr, int $restingHr): array
    {
        $hrr = max(1, $maxHr - $restingHr);
        $bounds = [];
        foreach (HeartRateZones::ZONE_PCT as $pct) {
            $bounds[] = (int) round($restingHr + $pct * $hrr);
        }

        return $this->buildZones($bounds);
    }

    /**
     * Compose 5-zone array from 4 interior boundaries. Z1 lower fixed at
     * 0, Z5 upper at -1 (open-ended). If rounding pushes adjacent
     * bounds onto the same value, nudge later up by 1 so adjacent
     * zones never collapse to zero width.
     *
     * @param  list<int>  $bounds  four interior bpm values, ascending
     * @return list<array{min:int, max:int}>
     */
    private function buildZones(array $bounds): array
    {
        for ($i = 1; $i < count($bounds); $i++) {
            if ($bounds[$i] <= $bounds[$i - 1]) {
                $bounds[$i] = $bounds[$i - 1] + 1;
            }
        }

        return [
            ['min' => 0, 'max' => $bounds[0]],
            ['min' => $bounds[0], 'max' => $bounds[1]],
            ['min' => $bounds[1], 'max' => $bounds[2]],
            ['min' => $bounds[2], 'max' => $bounds[3]],
            ['min' => $bounds[3], 'max' => -1],
        ];
    }

    /** @param  list<int>  $values */
    private function median(array $values): int
    {
        sort($values);
        $n = count($values);
        if ($n === 0) {
            return 0;
        }
        $mid = (int) floor($n / 2);
        if ($n % 2 === 1) {
            return $values[$mid];
        }

        return (int) round(($values[$mid - 1] + $values[$mid]) / 2);
    }

    private function defaultResult(): DerivationResult
    {
        return new DerivationResult(
            zones: array_map(
                fn (array $z): array => ['min' => (int) $z['min'], 'max' => (int) $z['max']],
                HeartRateZones::DEFAULTS,
            ),
            source: HeartRateZonesSource::Default,
            maxHeartRate: null,
            sampleCount: 0,
            age: null,
            restingHeartRate: null,
        );
    }

    private function sanitizeAge(?int $age): ?int
    {
        if ($age === null || $age < 5 || $age > 120) {
            return null;
        }

        return $age;
    }

    private function sanitizeRestingHr(?int $rhr): ?int
    {
        if ($rhr === null || $rhr < 30 || $rhr > 120) {
            return null;
        }

        return $rhr;
    }
}
