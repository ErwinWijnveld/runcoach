<?php

namespace App\Services\Onboarding;

use App\Enums\PaceConfidence;
use App\Enums\PaceDerivation;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\HeartRateZones;
use App\Support\Onboarding\FitnessSnapshot;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Builds a `FitnessSnapshot` reflecting the runner's CURRENT fitness, not
 * a 12-month average. The cascade falls through best-to-worst signal:
 *
 *   Tier 1  RecentThresholdEffort  ── one recent run looks like a tempo
 *                                     / time-trial effort. Highest trust.
 *   Tier 2  HrZonePace             ── per HR zone, take the fastest
 *                                     sustained pace in last 90 days,
 *                                     with a staleness penalty if the
 *                                     winning run isn't recent. PRIMARY
 *                                     PATH for runners with HR data.
 *   Tier 3  RecentAverage          ── pace-only fallback (last 30 days
 *                                     mean) when zone data is missing.
 *   Tier 4  Fallback               ── no recent activity at all.
 *
 * The service is read-only and idempotent. It never writes to the user
 * (HR zones live elsewhere via `HeartRateZoneDeriver`). Callers should
 * surface `confidence` + `derivation` to the runner so they understand
 * how their plan was paced.
 */
class FitnessSnapshotService
{
    /**
     * Window for HR-zone fastest-pace derivation. Older runs may reflect
     * a different fitness state — wider window = more risk of overstating
     * current capability.
     */
    public const ZONE_LOOKBACK_DAYS = 90;

    /** Minimum sustained run duration to count as a zone-pace candidate. */
    public const MIN_SUSTAINED_DURATION_SECONDS = 900; // 15 min

    /** Recent-tempo-effort window (Tier 1). */
    public const RECENT_THRESHOLD_LOOKBACK_DAYS = 30;

    /** Run length window for a candidate threshold effort. */
    public const THRESHOLD_MIN_DURATION_SECONDS = 1200; // 20 min

    public const THRESHOLD_MAX_DURATION_SECONDS = 3600; // 60 min

    /** Threshold effort detection: avg HR ≥ 85% of the runner's max. */
    public const THRESHOLD_HR_FRACTION = 0.85;

    /** Minimum distance for a Tier 1 candidate (km). */
    public const THRESHOLD_MIN_DISTANCE_KM = 4.0;

    /** Volume / longest-run windows. */
    public const VOLUME_LOOKBACK_DAYS = 28;

    public const LONGEST_RUN_LOOKBACK_DAYS = 56;

    public const RECENT_AVG_LOOKBACK_DAYS = 30;

    /**
     * Pace sanity bounds (sec/km). Anything outside is GPS junk —
     * 2:30/km is sub-WR pace, 12:00/km is walking.
     */
    public const PACE_SANITY_MIN_SECONDS_PER_KM = 150;

    public const PACE_SANITY_MAX_SECONDS_PER_KM = 720;

    /**
     * How many days old the fastest-zone-pace run can be before we apply
     * a staleness penalty (sec/km add) to acknowledge possible decline.
     *
     * Pairs: [max_age_days, penalty_seconds_added]. Evaluated in order;
     * the first whose `max_age_days` covers the run wins.
     */
    public const STALENESS_PENALTIES = [
        [30, 0],     // ≤ 30d: no penalty
        [60, 5],     // 30-60d: +5 sec/km
        [90, 10],    // 60-90d: +10 sec/km
    ];

    public const STALENESS_PENALTY_BEYOND = 15; // > 90d (defensive)

    /**
     * Distance-from-threshold offsets for Tier 3 (no HR data).
     * These mirror the gaps in Daniels' VDOT tables: easy ≈ T + 60-75s,
     * VO2max ≈ T - 20s. We use 30s easy-to-T as a conservative midpoint
     * because Tier 3 already represents low-confidence input.
     */
    public const TIER3_EASY_OFFSET = 30;       // easy = recent_avg, threshold = avg − 30

    public const TIER3_VO2MAX_OFFSET = -50;    // VO2max = recent_avg − 50

    /** Tier 1 / Tier 2 derived offsets (relative to threshold). */
    public const EASY_OFFSET_FROM_THRESHOLD = 75;     // easy ≈ T + 75 sec/km

    public const VO2MAX_OFFSET_FROM_THRESHOLD = -20;  // VO2max ≈ T − 20 sec/km

    /** Provider defaults when nothing about the runner is known (Tier 4). */
    public const FALLBACK_EASY_PACE = 360;       // 6:00/km

    public const FALLBACK_THRESHOLD_PACE = 300;  // 5:00/km

    public const FALLBACK_VO2MAX_PACE = 270;     // 4:30/km

    /** Number of qualifying runs required for a Tier 2 zone anchor. */
    public const ZONE_ANCHOR_MIN_HITS = 1;

    /**
     * "hasIntensityHistory" trigger: at least N distinct days with avg HR
     * in Z4 or Z5 in the last 60 days, OR a Tier 1 hit.
     */
    public const INTENSITY_HISTORY_MIN_HARD_DAYS = 2;

    public const INTENSITY_HISTORY_LOOKBACK_DAYS = 60;

    public function snapshot(User $user): FitnessSnapshot
    {
        $cascade = $this->deriveFromCascade($user);

        return $this->applySelfReportedOverrides($user, $cascade);
    }

    /**
     * Tier 0 — self-reported overrides. When the user has filled in their
     * baseline numbers during onboarding (`/onboarding/overview`), those
     * values win over the cascade. An empty self-report (both columns null)
     * falls through to the cascade unchanged.
     */
    private function applySelfReportedOverrides(User $user, FitnessSnapshot $cascade): FitnessSnapshot
    {
        $weeklyKm = $user->self_reported_weekly_km;
        $easyPace = $user->self_reported_easy_pace_seconds_per_km;

        if ($weeklyKm === null && $easyPace === null) {
            return $cascade;
        }

        return new FitnessSnapshot(
            thresholdPaceSecondsPerKm: $cascade->thresholdPaceSecondsPerKm,
            easyPaceSecondsPerKm: $easyPace ?? $cascade->easyPaceSecondsPerKm,
            vo2maxPaceSecondsPerKm: $cascade->vo2maxPaceSecondsPerKm,
            confidence: PaceConfidence::Low,
            derivation: PaceDerivation::SelfReported,
            weeklyKmRecent4Weeks: $weeklyKm !== null ? (float) $weeklyKm : $cascade->weeklyKmRecent4Weeks,
            weeklyRunsRecent4Weeks: $cascade->weeklyRunsRecent4Weeks,
            longestRunRecent8Weeks: $cascade->longestRunRecent8Weeks,
            maxHeartRate: $cascade->maxHeartRate,
            hasIntensityHistory: $cascade->hasIntensityHistory,
        );
    }

    private function deriveFromCascade(User $user): FitnessSnapshot
    {
        $runs = $this->loadCandidateRuns($user);
        $maxHr = $this->resolveMaxHr($user);

        $volume = $this->computeVolumeWindow($runs, self::VOLUME_LOOKBACK_DAYS);
        $longestRun = $this->computeLongestRun($runs, self::LONGEST_RUN_LOOKBACK_DAYS);
        $intensityHistory = $this->detectIntensityHistory($user, $runs, $maxHr);

        // Tier 1 — direct threshold effort. A successful Tier 1 hit is
        // itself proof of recent intensity, so force the flag true even
        // when `detectIntensityHistory` saw only one hard day.
        $tier1 = $this->deriveFromRecentThresholdEffort($runs, $maxHr);
        if ($tier1 !== null) {
            [$threshold, $easy, $vo2max] = $tier1;

            return new FitnessSnapshot(
                thresholdPaceSecondsPerKm: $threshold,
                easyPaceSecondsPerKm: $easy,
                vo2maxPaceSecondsPerKm: $vo2max,
                confidence: PaceConfidence::High,
                derivation: PaceDerivation::RecentThresholdEffort,
                weeklyKmRecent4Weeks: $volume['km_per_week'],
                weeklyRunsRecent4Weeks: $volume['runs_per_week'],
                longestRunRecent8Weeks: $longestRun,
                maxHeartRate: $maxHr,
                hasIntensityHistory: true,
            );
        }

        // Tier 2 — HR-zone fastest-pace mining.
        $tier2 = $this->deriveFromHrZones($user, $runs);
        if ($tier2 !== null) {
            return new FitnessSnapshot(
                thresholdPaceSecondsPerKm: $tier2['threshold'],
                easyPaceSecondsPerKm: $tier2['easy'],
                vo2maxPaceSecondsPerKm: $tier2['vo2max'],
                confidence: PaceConfidence::Medium,
                derivation: PaceDerivation::HrZonePace,
                weeklyKmRecent4Weeks: $volume['km_per_week'],
                weeklyRunsRecent4Weeks: $volume['runs_per_week'],
                longestRunRecent8Weeks: $longestRun,
                maxHeartRate: $maxHr,
                hasIntensityHistory: $intensityHistory,
            );
        }

        // Tier 3 — pace-only recent average.
        $tier3 = $this->deriveFromRecentAverage($runs);
        if ($tier3 !== null) {
            return new FitnessSnapshot(
                thresholdPaceSecondsPerKm: $tier3['threshold'],
                easyPaceSecondsPerKm: $tier3['easy'],
                vo2maxPaceSecondsPerKm: $tier3['vo2max'],
                confidence: PaceConfidence::Low,
                derivation: PaceDerivation::RecentAverage,
                weeklyKmRecent4Weeks: $volume['km_per_week'],
                weeklyRunsRecent4Weeks: $volume['runs_per_week'],
                longestRunRecent8Weeks: $longestRun,
                maxHeartRate: $maxHr,
                hasIntensityHistory: $intensityHistory,
            );
        }

        // Tier 4 — defaults.
        return new FitnessSnapshot(
            thresholdPaceSecondsPerKm: self::FALLBACK_THRESHOLD_PACE,
            easyPaceSecondsPerKm: self::FALLBACK_EASY_PACE,
            vo2maxPaceSecondsPerKm: self::FALLBACK_VO2MAX_PACE,
            confidence: PaceConfidence::None,
            derivation: PaceDerivation::Fallback,
            weeklyKmRecent4Weeks: $volume['km_per_week'],
            weeklyRunsRecent4Weeks: $volume['runs_per_week'],
            longestRunRecent8Weeks: $longestRun,
            maxHeartRate: $maxHr,
            hasIntensityHistory: $intensityHistory,
        );
    }

    /**
     * Pull every running activity in the last `ZONE_LOOKBACK_DAYS` window
     * once, then reuse for every tier. Eager-loaded into memory because
     * 90 days of running for a typical user is ≤ 60 rows.
     *
     * @return Collection<int, WearableActivity>
     */
    private function loadCandidateRuns(User $user): Collection
    {
        return WearableActivity::query()
            ->where('user_id', $user->id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->where('start_date', '>=', now()->subDays(self::ZONE_LOOKBACK_DAYS))
            ->whereNotNull('average_pace_seconds_per_km')
            ->orderByDesc('start_date')
            ->get();
    }

    private function resolveMaxHr(User $user): ?int
    {
        $zones = HeartRateZones::forUser($user);
        // The Z5 floor (zones[4]['min']) corresponds to ~90% of max HR
        // under both the percent-of-max and Karvonen schemes the
        // deriver uses. Reverse it to a max HR estimate.
        $z5Min = (int) ($zones[4]['min'] ?? 0);
        if ($z5Min <= 0) {
            return null;
        }

        // Z5 lower = 0.9 × maxHR (percent-of-max scheme), so divide.
        // Karvonen produces a slightly higher Z5 lower for low resting HR
        // — that just means the resulting maxHR estimate is conservative
        // (slightly low), which is the safe direction for Tier 1's
        // 85%-of-max threshold cutoff.
        return (int) round($z5Min / 0.9);
    }

    /**
     * @param  Collection<int, WearableActivity>  $runs
     * @return array{km_per_week: float, runs_per_week: float}
     */
    private function computeVolumeWindow(Collection $runs, int $days): array
    {
        $cutoff = now()->subDays($days);
        $window = $runs->filter(fn (WearableActivity $r) => $r->start_date >= $cutoff);

        $weeks = max(1.0, $days / 7.0);
        $totalKm = $window->sum(fn (WearableActivity $r) => ($r->distance_meters ?? 0) / 1000);

        return [
            'km_per_week' => round($totalKm / $weeks, 1),
            'runs_per_week' => round($window->count() / $weeks, 2),
        ];
    }

    /**
     * @param  Collection<int, WearableActivity>  $runs
     */
    private function computeLongestRun(Collection $runs, int $days): float
    {
        $cutoff = now()->subDays($days);
        $longest = $runs
            ->filter(fn (WearableActivity $r) => $r->start_date >= $cutoff)
            ->max(fn (WearableActivity $r) => $r->distance_meters ?? 0) ?? 0;

        return round($longest / 1000, 1);
    }

    /**
     * @param  Collection<int, WearableActivity>  $runs
     */
    private function detectIntensityHistory(User $user, Collection $runs, ?int $maxHr): bool
    {
        $cutoff = now()->subDays(self::INTENSITY_HISTORY_LOOKBACK_DAYS);
        if ($maxHr === null) {
            return false;
        }

        // Z4 lower bound from the user's stored zones — anything above
        // counts as a "hard" effort for intensity-history purposes.
        $zones = HeartRateZones::forUser($user);
        $z4Min = (int) ($zones[3]['min'] ?? 0);
        if ($z4Min <= 0) {
            return false;
        }

        $hardDays = $runs
            ->filter(fn (WearableActivity $r) => $r->start_date >= $cutoff)
            ->filter(function (WearableActivity $r) use ($z4Min): bool {
                $hr = $r->average_heartrate;

                return $hr !== null && (float) $hr >= $z4Min;
            })
            ->map(fn (WearableActivity $r) => $r->start_date->toDateString())
            ->unique()
            ->count();

        return $hardDays >= self::INTENSITY_HISTORY_MIN_HARD_DAYS;
    }

    /**
     * Tier 1: scan the last 30 days for a single run that walks like a
     * tempo / short race effort — duration in 20-60min, avg HR ≥ 85%
     * max, distance ≥ 4 km. Take its avg pace as threshold and derive
     * easy + vo2max from the standard offsets.
     *
     * Returns null when no candidate found OR when max HR is unknown.
     *
     * @param  Collection<int, WearableActivity>  $runs
     * @return array{0: int, 1: int, 2: int}|null [threshold, easy, vo2max]
     */
    private function deriveFromRecentThresholdEffort(Collection $runs, ?int $maxHr): ?array
    {
        if ($maxHr === null) {
            return null;
        }

        $hrFloor = $maxHr * self::THRESHOLD_HR_FRACTION;
        $cutoff = now()->subDays(self::RECENT_THRESHOLD_LOOKBACK_DAYS);

        $candidates = $runs->filter(function (WearableActivity $r) use ($hrFloor, $cutoff) {
            if ($r->start_date < $cutoff) {
                return false;
            }
            $duration = (int) ($r->duration_seconds ?? 0);
            if ($duration < self::THRESHOLD_MIN_DURATION_SECONDS) {
                return false;
            }
            if ($duration > self::THRESHOLD_MAX_DURATION_SECONDS) {
                return false;
            }
            $hr = $r->average_heartrate;
            if ($hr === null || (float) $hr < $hrFloor) {
                return false;
            }
            $km = (($r->distance_meters ?? 0) / 1000);
            if ($km < self::THRESHOLD_MIN_DISTANCE_KM) {
                return false;
            }
            $pace = (int) ($r->average_pace_seconds_per_km ?? 0);

            return $this->paceWithinSanityBounds($pace);
        });

        if ($candidates->isEmpty()) {
            return null;
        }

        // Pick the FASTEST eligible run — multiple tempos in the window
        // are a good problem to have; the runner's threshold is the
        // best demonstrated.
        $best = $candidates
            ->sortBy(fn (WearableActivity $r) => (int) $r->average_pace_seconds_per_km)
            ->first();

        $threshold = (int) $best->average_pace_seconds_per_km;
        $easy = $threshold + self::EASY_OFFSET_FROM_THRESHOLD;
        $vo2max = $this->clampPace($threshold + self::VO2MAX_OFFSET_FROM_THRESHOLD);

        return [$threshold, $easy, $vo2max];
    }

    /**
     * Tier 2: per HR zone (Z2..Z5), find the runner's fastest sustained
     * (≥ 15 min) pace in the last 90 days. Median-of-top-3 to absorb GPS
     * glitches. Apply a staleness penalty when the winning run isn't
     * recent. Maps:
     *   Z2 fastest pace → easy
     *   Z4 fastest pace → threshold
     *   Z5 fastest pace → vo2max
     *
     * Z3 is queried for diagnostic completeness only (no anchor mapping
     * — Z3 sits between easy and threshold in steady-state running and
     * doesn't anchor a distinct training pace).
     *
     * Requires at least 2 anchors (typically Z2 + Z4) before succeeding.
     *
     * @param  Collection<int, WearableActivity>  $runs
     * @return array{threshold: int, easy: int, vo2max: int}|null
     */
    private function deriveFromHrZones(User $user, Collection $runs): ?array
    {
        $zones = HeartRateZones::forUser($user);
        if (count($zones) < 5) {
            return null;
        }

        $sustained = $runs->filter(function (WearableActivity $r) {
            $duration = (int) ($r->duration_seconds ?? 0);
            if ($duration < self::MIN_SUSTAINED_DURATION_SECONDS) {
                return false;
            }
            if ($r->average_heartrate === null) {
                return false;
            }
            $pace = (int) ($r->average_pace_seconds_per_km ?? 0);

            return $this->paceWithinSanityBounds($pace);
        });

        if ($sustained->isEmpty()) {
            return null;
        }

        $easyAnchor = $this->fastestPaceInZone($sustained, $zones[1]);     // Z2
        $thresholdAnchor = $this->fastestPaceInZone($sustained, $zones[3]); // Z4
        $vo2maxAnchor = $this->fastestPaceInZone($sustained, $zones[4]);    // Z5

        $anchorsFound = ($easyAnchor !== null ? 1 : 0)
            + ($thresholdAnchor !== null ? 1 : 0)
            + ($vo2maxAnchor !== null ? 1 : 0);

        if ($anchorsFound < 2) {
            return null;
        }

        // Determine threshold: prefer the directly-anchored Z4 pace,
        // otherwise reverse-derive from whichever anchor is available.
        $threshold = $thresholdAnchor
            ?? ($easyAnchor !== null ? $easyAnchor - self::EASY_OFFSET_FROM_THRESHOLD : null)
            ?? ($vo2maxAnchor !== null ? $vo2maxAnchor - self::VO2MAX_OFFSET_FROM_THRESHOLD : null);

        if ($threshold === null) {
            return null;
        }

        $easy = $easyAnchor ?? ($threshold + self::EASY_OFFSET_FROM_THRESHOLD);
        $vo2max = $vo2maxAnchor ?? $this->clampPace($threshold + self::VO2MAX_OFFSET_FROM_THRESHOLD);

        // Sanity: enforce the natural ordering. If the runner's Z2 data
        // happens to include a tempo run that crept into a high heart
        // rate via cross-stress, the anchors can come out inverted.
        // Don't let that produce a plan where easy is faster than
        // threshold.
        if ($easy <= $threshold) {
            $easy = $threshold + self::EASY_OFFSET_FROM_THRESHOLD;
        }
        if ($vo2max >= $threshold) {
            $vo2max = $this->clampPace($threshold + self::VO2MAX_OFFSET_FROM_THRESHOLD);
        }

        return ['threshold' => $threshold, 'easy' => $easy, 'vo2max' => $vo2max];
    }

    /**
     * Tier 3: simple recent-average fallback. easy = avg, threshold =
     * avg − 30 sec/km, vo2max = avg − 50 sec/km. Only fires when the
     * window has at least 2 runs (a single data point is too noisy to
     * pace a multi-week plan off).
     *
     * @param  Collection<int, WearableActivity>  $runs
     * @return array{threshold: int, easy: int, vo2max: int}|null
     */
    private function deriveFromRecentAverage(Collection $runs): ?array
    {
        $cutoff = now()->subDays(self::RECENT_AVG_LOOKBACK_DAYS);
        $window = $runs
            ->filter(fn (WearableActivity $r) => $r->start_date >= $cutoff)
            ->filter(function (WearableActivity $r): bool {
                $pace = (int) ($r->average_pace_seconds_per_km ?? 0);

                return $this->paceWithinSanityBounds($pace);
            });

        if ($window->count() < 2) {
            return null;
        }

        $avg = (int) round($window->avg(fn (WearableActivity $r) => (int) $r->average_pace_seconds_per_km));

        $threshold = $this->clampPace($avg - self::TIER3_EASY_OFFSET);
        $vo2max = $this->clampPace($avg + self::TIER3_VO2MAX_OFFSET);

        return [
            'threshold' => $threshold,
            'easy' => $avg,
            'vo2max' => $vo2max,
        ];
    }

    /**
     * Find the fastest sustained pace whose avg HR falls into the given
     * zone, take the median of the top 3, then apply a staleness penalty
     * based on the AGE of the winning run.
     *
     * @param  Collection<int, WearableActivity>  $sustained
     * @param  array{min:int|float, max:int|float}  $zone
     */
    private function fastestPaceInZone(Collection $sustained, array $zone): ?int
    {
        $min = (int) $zone['min'];
        $max = (int) $zone['max']; // -1 = open-ended

        $inZone = $sustained->filter(function (WearableActivity $r) use ($min, $max): bool {
            $hr = (float) $r->average_heartrate;
            if ($hr < $min) {
                return false;
            }
            if ($max > 0 && $hr >= $max) {
                return false;
            }

            return true;
        })
            ->sortBy(fn (WearableActivity $r) => (int) $r->average_pace_seconds_per_km)
            ->values();

        if ($inZone->count() < self::ZONE_ANCHOR_MIN_HITS) {
            return null;
        }

        $top = $inZone->take(3);
        $paces = $top->map(fn (WearableActivity $r) => (int) $r->average_pace_seconds_per_km)->all();
        $medianPace = $this->median($paces);

        // Use the median pace's representative run for the staleness
        // check. Within the top-3 the most-recent run is the safer
        // anchor (we want "is this still doable", not "was this ever
        // doable"), so pick the most recent of the top-3.
        /** @var WearableActivity $representative */
        $representative = $top->sortByDesc(fn (WearableActivity $r) => $r->start_date)->first();
        $ageDays = $this->daysSince($representative->start_date);

        return $medianPace + $this->stalenessPenalty($ageDays);
    }

    private function stalenessPenalty(int $ageDays): int
    {
        foreach (self::STALENESS_PENALTIES as [$maxAge, $penalty]) {
            if ($ageDays <= $maxAge) {
                return $penalty;
            }
        }

        return self::STALENESS_PENALTY_BEYOND;
    }

    private function daysSince(Carbon|\DateTimeInterface $date): int
    {
        $carbon = $date instanceof Carbon ? $date : Carbon::instance($date);

        return (int) max(0, $carbon->diffInDays(now()));
    }

    private function paceWithinSanityBounds(int $pace): bool
    {
        return $pace >= self::PACE_SANITY_MIN_SECONDS_PER_KM
            && $pace <= self::PACE_SANITY_MAX_SECONDS_PER_KM;
    }

    private function clampPace(int $pace): int
    {
        return max(
            self::PACE_SANITY_MIN_SECONDS_PER_KM,
            min(self::PACE_SANITY_MAX_SECONDS_PER_KM, $pace),
        );
    }

    /** @param  list<int>  $values */
    private function median(array $values): int
    {
        if ($values === []) {
            return 0;
        }
        sort($values);
        $n = count($values);
        $mid = (int) floor($n / 2);
        if ($n % 2 === 1) {
            return $values[$mid];
        }

        return (int) round(($values[$mid - 1] + $values[$mid]) / 2);
    }
}
