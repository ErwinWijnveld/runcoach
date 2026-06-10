<?php

namespace App\Support\Intervals;

/**
 * Single source of truth for the interval-session data shape.
 *
 * CANONICAL (grouped) form — what we store in `training_days.intervals_json`
 * and carry in plan payloads:
 *
 *   [
 *     'warmup_seconds' => int|null,        // optional, time-based
 *     'steps' => [
 *       ['type' => 'block', 'reps' => int, 'work_distance_m' => int|null,
 *        'work_duration_seconds' => int|null, 'work_pace_seconds_per_km' => int|null,
 *        'recovery_seconds' => int],
 *       ['type' => 'rep', 'work_distance_m' => …, 'work_duration_seconds' => …,
 *        'work_pace_seconds_per_km' => …],     // single work, no recovery
 *       ['type' => 'rest', 'duration_seconds' => int],   // standalone recovery
 *     ],
 *     'cooldown_seconds' => int,           // REQUIRED, always present
 *   ]
 *
 * FLAT form — the legacy expanded segment list (still the wire format the
 * mobile app + WorkoutKit bridge consume, until they move to grouped):
 *
 *   [['kind' => 'warmup'|'work'|'recovery'|'cooldown', 'label' => string,
 *     'distance_m' => int|null, 'duration_seconds' => int|null,
 *     'target_pace_seconds_per_km' => int|null], …]
 *
 * `collapse()` folds flat → grouped (greedy: consecutive identical work+recovery
 * pairs become one block with a reps count). `expand()` unrolls grouped → flat.
 * `normalize()` accepts EITHER form and returns the clamped canonical grouped
 * form (or null when there's nothing meaningful). The algorithm mirrors the
 * Filament coach editor's proven parse/serialize round-trip.
 */
class IntervalBlueprint
{
    public const WARMUP_MAX_SECONDS = 120;

    public const WARMUP_DEFAULT_SECONDS = 60;

    public const RECOVERY_MIN_SECONDS = 15;

    public const RECOVERY_DEFAULT_SECONDS = 90;

    public const COOLDOWN_MIN_SECONDS = 60;

    public const COOLDOWN_MAX_SECONDS = 600;

    public const COOLDOWN_DEFAULT_SECONDS = 300;

    public const REPS_MIN = 1;

    public const REPS_MAX = 60;

    public const WORK_DISTANCE_DEFAULT_M = 400;

    /**
     * Jog pace (warmup / recoveries / cooldown) for `estimateTotalKm`,
     * expressed as an offset from the blueprint's average work pace.
     * Consistent with the optimizer's recovery delta (baseline+60 vs work
     * baseline−50 ⇒ recovery ≈ work+110) and the old builder estimate
     * (easy ≈ work+95).
     */
    public const ESTIMATE_JOG_OFFSET_FROM_WORK = 100;

    /** Jog pace when no work step carries a pace (6:00/km). */
    public const ESTIMATE_FALLBACK_JOG_PACE_SECONDS = 360;

    public const ESTIMATE_JOG_PACE_MIN_SECONDS = 180;

    public const ESTIMATE_JOG_PACE_MAX_SECONDS = 720;

    /**
     * Accept grouped OR flat input and return the clamped canonical grouped
     * form. Null when there are no meaningful work steps.
     *
     * @return array<string, mixed>|null
     */
    public static function normalize(mixed $input): ?array
    {
        if (self::isGrouped($input)) {
            return self::normalizeGrouped($input);
        }
        if (is_array($input) && array_is_list($input)) {
            $collapsed = self::collapse($input);

            return $collapsed === null ? null : self::normalizeGrouped($collapsed);
        }

        return null;
    }

    public static function isGrouped(mixed $value): bool
    {
        return is_array($value) && array_key_exists('steps', $value) && is_array($value['steps']);
    }

    /**
     * Compact human-readable description of the normalized WORK SETS, e.g.
     * "4×800m @4:30/km (rec 90s)". Warm-up and cool-down are deliberately
     * omitted — they're server-managed bookkeeping the runner never reviews
     * (this string renders verbatim on the plan-revision diff card). Accepts
     * either form (like `normalize`); null when there's nothing meaningful.
     * The AdjustPlan diff embeds this so the agent describes the session
     * that was actually stored, not the one it sent.
     */
    public static function summary(mixed $input): ?string
    {
        $g = self::normalize($input);
        if ($g === null) {
            return null;
        }

        $parts = [];

        foreach ($g['steps'] as $step) {
            if ($step['type'] === 'rest') {
                $parts[] = 'rest '.$step['duration_seconds'].'s';

                continue;
            }

            $reps = $step['type'] === 'block' ? $step['reps'] : 1;
            $work = $step['work_distance_m'] !== null
                ? $step['work_distance_m'].'m'
                : $step['work_duration_seconds'].'s';
            $piece = $reps.'×'.$work;
            if ($step['work_pace_seconds_per_km'] !== null) {
                $piece .= ' @'.self::formatPace($step['work_pace_seconds_per_km']).'/km';
            }
            if ($step['type'] === 'block') {
                $piece .= ' (rec '.$step['recovery_seconds'].'s)';
            }
            $parts[] = $piece;
        }

        return implode(' + ', $parts);
    }

    /**
     * Human-readable notes when `normalize()` clamps the WORK structure, so
     * the agent can tell the runner what the server changed. Warm-up /
     * cool-down clamps are deliberately NOT noted: they're server-managed
     * defaults the runner never reviews, and these notes render verbatim on
     * the plan-revision diff card. Empty for canonical input, for legacy
     * flat input (no field-by-field mapping exists), and for input
     * `normalize()` rejects outright — callers detect rejection via
     * `normalize() === null` and word the substitution message themselves.
     *
     * @return list<string>
     */
    public static function normalizationNotes(mixed $input): array
    {
        if (! self::isGrouped($input) || self::normalize($input) === null) {
            return [];
        }

        $notes = [];

        foreach ($input['steps'] as $step) {
            if (! is_array($step) || ($step['type'] ?? 'block') !== 'block') {
                continue;
            }
            $requested = (int) ($step['reps'] ?? 1);
            $stored = max(self::REPS_MIN, min(self::REPS_MAX, $requested));
            if ($stored !== $requested) {
                $notes[] = 'Rep count set to '.$stored.' (you asked for '.$requested.'; allowed range is '
                    .self::REPS_MIN.'–'.self::REPS_MAX.').';
            }
        }

        return $notes;
    }

    /**
     * Estimated TOTAL session distance (km, 1 decimal) for a blueprint —
     * the single definition of an interval day's `target_km`, enforced on
     * every write path (optimizer pass, TrainingDay saving hook, backfill
     * migration) so the stored distance can never drift from the session
     * structure.
     *
     * Pure function of the blueprint — no user/snapshot input — so the same
     * structure yields the same km no matter which write path ran:
     *  - work steps count their literal distance; duration-based work
     *    converts via its own pace, falling back to the work-set average;
     *  - time-based segments (warmup, recoveries, rests, cooldown) convert
     *    at a jog pace = avg work pace + ESTIMATE_JOG_OFFSET_FROM_WORK,
     *    clamped, or ESTIMATE_FALLBACK_JOG_PACE_SECONDS when no work step
     *    carries a pace.
     *
     * Accepts either form (like `normalize`); null when there's nothing
     * meaningful to estimate.
     */
    public static function estimateTotalKm(mixed $input): ?float
    {
        $g = self::normalize($input);
        if ($g === null) {
            return null;
        }

        $avgWorkPace = self::averageWorkPace($g);
        $jogPace = self::estimateJogPace($avgWorkPace);

        $meters = 0.0;
        if ($g['warmup_seconds'] !== null) {
            $meters += $g['warmup_seconds'] / $jogPace * 1000;
        }

        foreach ($g['steps'] as $step) {
            if (($step['type'] ?? null) === 'rest') {
                $meters += $step['duration_seconds'] / $jogPace * 1000;

                continue;
            }

            $reps = ($step['type'] ?? 'block') === 'block' ? (int) $step['reps'] : 1;

            if (($step['work_distance_m'] ?? null) !== null) {
                $meters += $reps * $step['work_distance_m'];
            } elseif (($step['work_duration_seconds'] ?? null) !== null) {
                $workPace = $step['work_pace_seconds_per_km'] ?? $avgWorkPace ?? $jogPace;
                $meters += $reps * ($step['work_duration_seconds'] / $workPace * 1000);
            }

            if (($step['type'] ?? null) === 'block') {
                $meters += $reps * ($step['recovery_seconds'] / $jogPace * 1000);
            }
        }

        $meters += $g['cooldown_seconds'] / $jogPace * 1000;

        return round($meters / 1000, 1);
    }

    /**
     * Estimated jog pace (warmup / recoveries / cooldown) for a blueprint's
     * average work pace: work + ESTIMATE_JOG_OFFSET_FROM_WORK, clamped, or
     * the fallback when no work step carries a pace. Shared by
     * `estimateTotalKm` and the compliance scorer's interval pace band.
     */
    public static function estimateJogPace(?int $avgWorkPaceSecondsPerKm): int
    {
        if ($avgWorkPaceSecondsPerKm === null) {
            return self::ESTIMATE_FALLBACK_JOG_PACE_SECONDS;
        }

        return max(
            self::ESTIMATE_JOG_PACE_MIN_SECONDS,
            min(self::ESTIMATE_JOG_PACE_MAX_SECONDS, $avgWorkPaceSecondsPerKm + self::ESTIMATE_JOG_OFFSET_FROM_WORK),
        );
    }

    /**
     * Distance (km) covered by the WORK steps alone — no warmup, recoveries
     * or cooldown. This is the compliance scorer's "reps demonstrably
     * incomplete" floor: an actual run shorter than this can't have finished
     * the prescribed work. Distance-based work counts literal meters;
     * duration-based work converts via its own pace, falling back to the
     * work-set average, then the jog fallback. Accepts either form (like
     * `normalize`); null when there's nothing meaningful.
     */
    public static function workDistanceKm(mixed $input): ?float
    {
        $g = self::normalize($input);
        if ($g === null) {
            return null;
        }

        $avgWorkPace = self::averageWorkPace($g);

        $meters = 0.0;
        foreach ($g['steps'] as $step) {
            if (($step['type'] ?? null) === 'rest') {
                continue;
            }

            $reps = ($step['type'] ?? 'block') === 'block' ? (int) $step['reps'] : 1;

            if (($step['work_distance_m'] ?? null) !== null) {
                $meters += $reps * $step['work_distance_m'];
            } elseif (($step['work_duration_seconds'] ?? null) !== null) {
                $workPace = $step['work_pace_seconds_per_km'] ?? $avgWorkPace ?? self::ESTIMATE_FALLBACK_JOG_PACE_SECONDS;
                $meters += $reps * ($step['work_duration_seconds'] / $workPace * 1000);
            }
        }

        return $meters > 0 ? round($meters / 1000, 2) : null;
    }

    /**
     * Unweighted mean of the work steps' paces (per-STEP, not per-rep) —
     * the same definition as `TrainingDay::workSetAveragePaceSecondsPerKm`.
     *
     * @param  array<string, mixed>  $grouped
     */
    private static function averageWorkPace(array $grouped): ?int
    {
        $workPaces = [];
        foreach ($grouped['steps'] as $step) {
            if (($step['type'] ?? null) === 'rest') {
                continue;
            }
            $pace = $step['work_pace_seconds_per_km'] ?? null;
            if (is_int($pace) && $pace > 0) {
                $workPaces[] = $pace;
            }
        }

        return $workPaces === [] ? null : (int) round(array_sum($workPaces) / count($workPaces));
    }

    private static function formatPace(int $secondsPerKm): string
    {
        return intdiv($secondsPerKm, 60).':'.str_pad((string) ($secondsPerKm % 60), 2, '0', STR_PAD_LEFT);
    }

    /**
     * Fold a flat segment list into the canonical grouped form.
     *
     * @param  list<array<string,mixed>>|null  $flat
     * @return array<string, mixed>|null
     */
    public static function collapse(?array $flat): ?array
    {
        if ($flat === null || $flat === []) {
            return null;
        }

        $warmup = null;
        $cooldown = null;
        $middle = [];

        foreach ($flat as $seg) {
            if (! is_array($seg)) {
                continue;
            }
            $kind = (string) ($seg['kind'] ?? 'work');
            if ($kind === 'warmup' && $warmup === null) {
                $warmup = $seg;
            } elseif ($kind === 'cooldown') {
                $cooldown = $seg;
            } else {
                $middle[] = $seg;
            }
        }

        $steps = [];
        $count = count($middle);
        $i = 0;
        while ($i < $count) {
            $cur = $middle[$i];
            $kind = $cur['kind'] ?? 'work';

            if ($kind === 'recovery') {
                $steps[] = ['type' => 'rest', 'duration_seconds' => (int) ($cur['duration_seconds'] ?? self::RECOVERY_DEFAULT_SECONDS)];
                $i++;

                continue;
            }

            $next = $middle[$i + 1] ?? null;
            if (! is_array($next) || ($next['kind'] ?? '') !== 'recovery') {
                $steps[] = self::workToStep($cur, null, 1);
                $i++;

                continue;
            }

            $reps = 1;
            $j = $i + 2;
            while ($j + 1 < $count
                && ($middle[$j]['kind'] ?? '') === 'work'
                && ($middle[$j + 1]['kind'] ?? '') === 'recovery'
                && self::workEquals($middle[$j], $cur)
                && self::recoveryEquals($middle[$j + 1], $next)
            ) {
                $reps++;
                $j += 2;
            }

            $steps[] = self::workToStep($cur, $next, $reps);
            $i = $j;
        }

        if ($steps === []) {
            return null;
        }

        return [
            'warmup_seconds' => $warmup !== null ? (int) ($warmup['duration_seconds'] ?? self::WARMUP_DEFAULT_SECONDS) : null,
            'steps' => $steps,
            'cooldown_seconds' => $cooldown !== null ? (int) ($cooldown['duration_seconds'] ?? self::COOLDOWN_DEFAULT_SECONDS) : self::COOLDOWN_DEFAULT_SECONDS,
        ];
    }

    /**
     * Unroll the canonical grouped form into a flat segment list.
     *
     * @param  array<string,mixed>|null  $grouped
     * @return list<array<string,mixed>>|null
     */
    public static function expand(?array $grouped): ?array
    {
        $g = self::normalizeGrouped($grouped ?? []);
        if ($g === null) {
            return null;
        }

        $segments = [];

        if ($g['warmup_seconds'] !== null) {
            $segments[] = self::segment('warmup', 'Warm up', null, $g['warmup_seconds'], null);
        }

        foreach ($g['steps'] as $step) {
            if (($step['type'] ?? null) === 'rest') {
                $segments[] = self::segment('recovery', 'Rest', null, $step['duration_seconds'], null);

                continue;
            }

            $dist = $step['work_distance_m'] ?? null;
            $dur = $step['work_duration_seconds'] ?? null;
            $pace = $step['work_pace_seconds_per_km'] ?? null;
            $label = $dist !== null ? "{$dist}m rep" : "{$dur}s rep";
            $reps = ($step['type'] ?? 'block') === 'block' ? (int) $step['reps'] : 1;

            for ($r = 0; $r < $reps; $r++) {
                $segments[] = self::segment('work', $label, $dist, $dur, $pace);
                if (($step['type'] ?? null) === 'block') {
                    $segments[] = self::segment('recovery', 'Recovery', null, $step['recovery_seconds'], null);
                }
            }
        }

        $segments[] = self::segment('cooldown', 'Cool down', null, $g['cooldown_seconds'], null);

        return $segments;
    }

    /**
     * Clamp + canonicalise a grouped structure. Drops empty step lists to null.
     *
     * @param  array<string,mixed>  $grouped
     * @return array<string, mixed>|null
     */
    private static function normalizeGrouped(array $grouped): ?array
    {
        $rawSteps = is_array($grouped['steps'] ?? null) ? $grouped['steps'] : [];
        $steps = [];

        foreach ($rawSteps as $step) {
            if (! is_array($step)) {
                continue;
            }
            $type = $step['type'] ?? 'block';

            if ($type === 'rest') {
                $steps[] = [
                    'type' => 'rest',
                    'duration_seconds' => max(self::RECOVERY_MIN_SECONDS, (int) ($step['duration_seconds'] ?? self::RECOVERY_DEFAULT_SECONDS)),
                ];

                continue;
            }

            $dist = isset($step['work_distance_m']) && (int) $step['work_distance_m'] > 0 ? (int) $step['work_distance_m'] : null;
            $dur = isset($step['work_duration_seconds']) && (int) $step['work_duration_seconds'] > 0 ? (int) $step['work_duration_seconds'] : null;
            if ($dist === null && $dur === null) {
                $dist = self::WORK_DISTANCE_DEFAULT_M;
            }
            if ($dist !== null) {
                $dur = null; // prefer distance when both supplied
            }
            $pace = isset($step['work_pace_seconds_per_km']) && (int) $step['work_pace_seconds_per_km'] > 0
                ? (int) $step['work_pace_seconds_per_km']
                : null;

            if ($type === 'block') {
                $steps[] = [
                    'type' => 'block',
                    'reps' => max(self::REPS_MIN, min(self::REPS_MAX, (int) ($step['reps'] ?? 1))),
                    'work_distance_m' => $dist,
                    'work_duration_seconds' => $dur,
                    'work_pace_seconds_per_km' => $pace,
                    'recovery_seconds' => max(self::RECOVERY_MIN_SECONDS, (int) ($step['recovery_seconds'] ?? self::RECOVERY_DEFAULT_SECONDS)),
                ];
            } else {
                $steps[] = [
                    'type' => 'rep',
                    'work_distance_m' => $dist,
                    'work_duration_seconds' => $dur,
                    'work_pace_seconds_per_km' => $pace,
                ];
            }
        }

        if ($steps === []) {
            return null;
        }

        $warmup = $grouped['warmup_seconds'] ?? null;
        $warmup = is_numeric($warmup) && (int) $warmup > 0
            ? max(1, min(self::WARMUP_MAX_SECONDS, (int) $warmup))
            : null;

        $cooldown = max(
            self::COOLDOWN_MIN_SECONDS,
            min(self::COOLDOWN_MAX_SECONDS, (int) ($grouped['cooldown_seconds'] ?? self::COOLDOWN_DEFAULT_SECONDS)),
        );

        return [
            'warmup_seconds' => $warmup,
            'steps' => $steps,
            'cooldown_seconds' => $cooldown,
        ];
    }

    /**
     * @param  array<string,mixed>  $work
     * @param  array<string,mixed>|null  $recovery
     * @return array<string, mixed>
     */
    private static function workToStep(array $work, ?array $recovery, int $reps): array
    {
        $dist = isset($work['distance_m']) && $work['distance_m'] !== null ? (int) $work['distance_m'] : null;
        $dur = isset($work['duration_seconds']) && $work['duration_seconds'] !== null ? (int) $work['duration_seconds'] : null;
        $pace = isset($work['target_pace_seconds_per_km']) && $work['target_pace_seconds_per_km'] !== null
            ? (int) $work['target_pace_seconds_per_km']
            : null;

        if ($recovery === null) {
            return [
                'type' => 'rep',
                'work_distance_m' => $dist,
                'work_duration_seconds' => $dur,
                'work_pace_seconds_per_km' => $pace,
            ];
        }

        return [
            'type' => 'block',
            'reps' => max(self::REPS_MIN, min(self::REPS_MAX, $reps)),
            'work_distance_m' => $dist,
            'work_duration_seconds' => $dur,
            'work_pace_seconds_per_km' => $pace,
            'recovery_seconds' => (int) ($recovery['duration_seconds'] ?? self::RECOVERY_DEFAULT_SECONDS),
        ];
    }

    /**
     * @param  array<string,mixed>  $a
     * @param  array<string,mixed>  $b
     */
    private static function workEquals(array $a, array $b): bool
    {
        return ($a['distance_m'] ?? null) === ($b['distance_m'] ?? null)
            && ($a['duration_seconds'] ?? null) === ($b['duration_seconds'] ?? null)
            && ($a['target_pace_seconds_per_km'] ?? null) === ($b['target_pace_seconds_per_km'] ?? null);
    }

    /**
     * @param  array<string,mixed>  $a
     * @param  array<string,mixed>  $b
     */
    private static function recoveryEquals(array $a, array $b): bool
    {
        return ($a['duration_seconds'] ?? null) === ($b['duration_seconds'] ?? null);
    }

    /**
     * @return array<string, mixed>
     */
    private static function segment(string $kind, string $label, ?int $distanceM, ?int $durationSeconds, ?int $pace): array
    {
        return [
            'kind' => $kind,
            'label' => $label,
            'distance_m' => $distanceM,
            'duration_seconds' => $durationSeconds,
            'target_pace_seconds_per_km' => $pace,
        ];
    }
}
