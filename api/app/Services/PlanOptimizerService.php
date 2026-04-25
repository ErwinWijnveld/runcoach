<?php

namespace App\Services;

use App\Enums\TrainingType;
use App\Models\User;
use App\Support\PlanPayload;
use Carbon\Carbon;

/**
 * Deterministic post-processor for schedule payloads coming out of the AI
 * `create_schedule` / `edit_schedule` tools.
 *
 * The AI owns intent: which weeks, which days of the week, what type of
 * session, target distance, free-form description. Everything mechanical —
 * paces, titles, weekly km totals, goal target_date alignment — is computed
 * here from the runner's own Strava-derived pace baseline so the plan is
 * internally consistent no matter how sloppy the model gets.
 *
 * Idempotent: running optimize() twice yields the same payload.
 */
class PlanOptimizerService
{
    /** Seconds-per-km offsets from the runner's steady baseline pace. */
    private const PACE_DELTAS = [
        TrainingType::Easy->value => 30,
        TrainingType::LongRun->value => 15,
        TrainingType::Tempo->value => -25,
        TrainingType::Interval->value => -50,
        TrainingType::Threshold->value => -25,
    ];

    /** Pace delta for between-reps recovery jogging inside an interval session. */
    private const PACE_DELTA_INTERVAL_RECOVERY = 60;

    /**
     * Below this distance a day can't credibly be called a "long run",
     * regardless of the AI's labeling. Demoted to `easy`.
     */
    private const MIN_LONG_RUN_KM = 6.0;

    /** Fallback baseline when the runner has no profile yet (5:30/km). */
    private const DEFAULT_BASELINE_PACE = 330;

    /**
     * Optimize a CreateSchedule-shaped payload. Safe to call on EditSchedule
     * payloads too — same shape (`schedule.weeks[].days[]`).
     *
     * Pass `alignRaceDay = true` to also:
     *   (a) overwrite `payload.target_date` with the date of the plan's final
     *       training day, and
     *   (b) title that final day with `goal_name` (since it IS the race).
     * This is what CreateSchedule wants. EditSchedule passes `false` to
     * preserve user-set target dates and day titles — an edit that renames
     * a Sunday run to "Sunday" shouldn't get clobbered into "Race Name".
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function optimize(array $payload, User $user, bool $alignRaceDay = true): array
    {
        if (! isset($payload['schedule']['weeks']) || ! is_array($payload['schedule']['weeks'])) {
            return $payload;
        }

        $baseline = $this->resolveBaselinePace($user);
        // Always read goal_name regardless of alignRaceDay. enforceRaceDay
        // nulls the title on race day on every call (create AND edit) so
        // generateTitles needs goal_name to relabel it back; otherwise the
        // race day falls through to dayTitle() and ends up as e.g.
        // "10km Tempo" instead of the actual goal name.
        $goalName = $payload['goal_name'] ?? null;

        // Hard guardrails that apply to EVERY call — create and edit alike.
        // These are structural invariants the plan must satisfy no matter
        // who generated it: availability, min run length, no duplicate
        // days, no days past the race, a race-day entry MUST exist on
        // target_date, and that day's km/type/pace must match the goal.
        //
        // `ensureRaceDayEntry` + `enforceRaceDay` running on edits is
        // critical: the agent sometimes removes the race entry during
        // verify-loop cleanup (thinking it's a duplicate) and without
        // re-adding it, the plan has no entry on target_date.
        $payload = $this->enforcePreferredWeekdays($payload);
        $payload = $this->enforceMinimumRunLength($payload, $user);
        $payload = $this->deduplicateDaysPerWeek($payload);
        // ensureRaceDayEntry runs BEFORE dropDaysPastTarget so it can
        // salvage a misplaced race-like day (e.g. agent miscounted weeks
        // and put the race past target_date) and relocate it to the
        // correct slot, preserving the agent's description / intervals.
        // Otherwise dropDaysPastTarget would discard the agent's content
        // and we'd fall back to a generic "Goal day. Execute your plan."
        // skeleton.
        $payload = $this->ensureRaceDayEntry($payload);
        $payload = $this->dropDaysPastTarget($payload);
        $payload = $this->enforceRaceDay($payload);

        // Create-only: when NO target_date was stated (open-ended /
        // general-fitness), snap target_date to the plan's last training
        // day so the dashboard / schedule views have something to anchor
        // on. Skipped on edits because the user may have edited the plan
        // with full knowledge of what they want the end date to be.
        if ($alignRaceDay) {
            $payload = $this->alignTargetDateToLastDay($payload);
        }

        $payload = $this->reclassifyLongRuns($payload);
        $payload = $this->promoteLongRuns($payload);
        $payload = $this->computePaces($payload, $baseline);
        $payload = $this->generateTitles($payload, $goalName);
        $payload = $this->recalculateWeeklyTotals($payload);

        return $payload;
    }

    /**
     * Bump every running day up to `max(4km, 40% of the runner's typical
     * single-run distance)`, capped at 6km so advanced runners can still
     * have short shakeouts. The AI has been observed to emit 2-4km runs
     * for a runner whose typical run is 8km+ — that's shorter than they
     * currently run in a single session, which makes no training sense.
     *
     * Race day is not exempt from the bump because its km is already set
     * by `enforceRaceDay` to the goal distance, which is always ≥ minimum.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function enforceMinimumRunLength(array $payload, User $user): array
    {
        $profile = $user->runningProfile()->first();
        $metrics = $profile?->metrics ?? [];
        $weeklyKm = (float) ($metrics['weekly_avg_km'] ?? 0);
        $weeklyRuns = max(1, (int) ($metrics['weekly_avg_runs'] ?? 1));
        $avgRunKm = $weeklyKm / $weeklyRuns;

        // 40% of current session length, floor 4, ceiling 6. For an 8km/run
        // runner this bumps to 4km. For a 20km/run marathon runner the cap
        // keeps the floor at 6 — short shakeouts stay legal.
        $minKm = max(4.0, min(6.0, $avgRunKm * 0.4));
        $minKm = round($minKm, 1);

        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            foreach (($week['days'] ?? []) as $di => $day) {
                $km = (float) ($day['target_km'] ?? 0);
                if ($km > 0 && $km < $minKm) {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['target_km'] = $minKm;
                }
            }
        }

        return $payload;
    }

    /**
     * If the payload carries a `preferred_weekdays` list, drop any training
     * day whose `day_of_week` isn't in it. The AI has been observed to
     * silently violate this constraint (user picks Mon/Tue/Wed/Fri and the
     * agent schedules on Sat/Sun anyway) — server-side enforcement makes
     * it non-negotiable. Weeks that empty out as a result are dropped.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function enforcePreferredWeekdays(array $payload): array
    {
        $preferred = $payload['preferred_weekdays'] ?? null;
        if (! is_array($preferred) || empty($preferred)) {
            return $payload;
        }

        $allowed = array_map('intval', $preferred);

        // Race-day entry is exempt from the weekday filter — the runner
        // races on that date regardless of what weekdays they normally
        // train on. Without this escape hatch, an edit that re-runs this
        // pass would silently drop the Sunday race entry on a plan whose
        // preferred_weekdays is Mon/Wed/Fri.
        $stated = $payload['target_date'] ?? null;
        $target = (is_string($stated) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated))
            ? Carbon::parse($stated)->startOfDay()
            : null;
        $planStart = Carbon::now()->startOfWeek();

        $weeks = [];
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            $weekNum = (int) ($week['week_number'] ?? 1);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            $kept = [];
            foreach (($week['days'] ?? []) as $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                $isRaceDay = $target !== null
                    && $dow >= 1 && $dow <= 7
                    && $weekStart->copy()->addDays($dow - 1)->equalTo($target);
                if ($isRaceDay || in_array($dow, $allowed, true)) {
                    $kept[] = $day;
                }
            }
            if ($kept === []) {
                continue;
            }
            $week['days'] = $kept;
            $weeks[] = $week;
        }
        $payload['schedule']['weeks'] = $weeks;

        return $payload;
    }

    /**
     * Add a training entry on `target_date` if none exists. Some AI-generated
     * plans stop a few days short of the race (e.g. plan ends Sat, race is
     * the following Wed); others place the final day on target_date but
     * elsewhere the race week is missing entirely. Either way, the runner
     * must have a training entry ON race day — that's the entire point of
     * the plan.
     *
     * Before falling back to a generic skeleton, the method scans the
     * agent's existing days for a probable race entry (target_km close to
     * goal distance) and relocates it to target_date, preserving its
     * description / intervals / pace. This handles the common bug where
     * the agent miscounts weeks and places the race a week too far —
     * we don't want `dropDaysPastTarget` to discard the agent's content
     * and replace it with "Goal day. Execute your plan."
     *
     * `enforceRaceDay` fills in pace/type/km on the next pass, and
     * `generateTitles` titles it with `goal_name`.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function ensureRaceDayEntry(array $payload): array
    {
        $stated = $payload['target_date'] ?? null;
        if (! is_string($stated) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated)) {
            return $payload;
        }

        $target = Carbon::parse($stated)->startOfDay();
        $planStart = Carbon::now()->startOfWeek();
        $dowTarget = (int) $target->isoWeekday();
        $targetWeekNum = (int) $planStart->diffInWeeks($target) + 1;

        // Check whether a day already exists on target_date.
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            $weekNum = (int) ($week['week_number'] ?? 0);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            foreach (($week['days'] ?? []) as $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                $date = $weekStart->copy()->addDays($dow - 1);
                if ($date->equalTo($target)) {
                    return $payload; // already present, nothing to do
                }
            }
        }

        // Try to salvage a misplaced race day from the agent's input
        // before falling back to a skeleton. Heuristic: a day whose
        // target_km is within 15% of the goal distance is almost
        // certainly the race entry the agent intended, just on the
        // wrong calendar slot.
        $goalKm = PlanPayload::goalKm($payload);
        $salvaged = null;
        if ($goalKm !== null) {
            [$salvaged, $payload] = $this->extractMisplacedRaceDay($payload, $goalKm);
        }

        $newDay = $salvaged ?? [
            'type' => TrainingType::Tempo->value,
            'description' => 'Goal day. Execute your plan.',
        ];
        // Force the relocated/skeleton entry onto target_date's weekday
        // so enforceRaceDay sees it where it belongs.
        $newDay['day_of_week'] = $dowTarget;

        // Add to the target week if it already exists...
        foreach (($payload['schedule']['weeks'] ?? []) as $wi => $week) {
            if ((int) ($week['week_number'] ?? 0) === $targetWeekNum) {
                $payload['schedule']['weeks'][$wi]['days'][] = $newDay;

                return $payload;
            }
        }

        // ...otherwise create a minimal race week.
        $payload['schedule']['weeks'][] = [
            'week_number' => $targetWeekNum,
            'focus' => 'Race week',
            'days' => [$newDay],
        ];

        return $payload;
    }

    /**
     * Find a day that looks like a misplaced race entry, remove it from
     * the schedule, and return both the extracted day and the mutated
     * payload. Returns `[null, $payload]` if no match.
     *
     * Heuristic combines two signals to avoid grabbing a regular long
     * run: the day's `type` must be `tempo` (the agent's race-day
     * convention — see planDesignPrinciples and enforceRaceDay) AND its
     * `target_km` must be within 10% of the goal distance. Preference:
     * closest km match wins; ties broken by latest position (the agent
     * typically places the race entry last).
     *
     * @param  array<string, mixed>  $payload
     * @return array{0: array<string, mixed>|null, 1: array<string, mixed>}
     */
    private function extractMisplacedRaceDay(array $payload, float $goalKm): array
    {
        $tolerance = max(0.5, $goalKm * 0.1);

        $bestWi = null;
        $bestDi = null;
        $bestDelta = INF;

        foreach (($payload['schedule']['weeks'] ?? []) as $wi => $week) {
            foreach (($week['days'] ?? []) as $di => $day) {
                if (($day['type'] ?? null) !== TrainingType::Tempo->value) {
                    continue;
                }
                $km = (float) ($day['target_km'] ?? 0);
                if ($km <= 0) {
                    continue;
                }
                $delta = abs($km - $goalKm);
                if ($delta > $tolerance) {
                    continue;
                }
                // <= so later-positioned ties (typical race-entry spot) win.
                if ($delta <= $bestDelta) {
                    $bestDelta = $delta;
                    $bestWi = $wi;
                    $bestDi = $di;
                }
            }
        }

        if ($bestWi === null || $bestDi === null) {
            return [null, $payload];
        }

        $day = $payload['schedule']['weeks'][$bestWi]['days'][$bestDi];
        array_splice($payload['schedule']['weeks'][$bestWi]['days'], $bestDi, 1);
        $payload['schedule']['weeks'][$bestWi]['days'] = array_values(
            $payload['schedule']['weeks'][$bestWi]['days']
        );

        return [$day, $payload];
    }

    /**
     * Counterpart to `reclassifyLongRuns`: if a week has no `long_run` but
     * does have a clear longest-km day (typed `easy`) ≥ MIN_LONG_RUN_KM,
     * promote that day so the plan actually contains weekly long runs.
     * The AI sometimes generates plans that are all easy runs — from a
     * race-training perspective that's broken, long runs are the backbone.
     *
     * Never promotes over quality days (tempo/interval/threshold) — those
     * ARE intentional choices. Only elevates an existing easy day.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function promoteLongRuns(array $payload): array
    {
        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            $days = $week['days'] ?? [];
            if (empty($days)) {
                continue;
            }

            $hasLongRun = false;
            foreach ($days as $day) {
                if (($day['type'] ?? '') === TrainingType::LongRun->value) {
                    $hasLongRun = true;
                    break;
                }
            }
            if ($hasLongRun) {
                continue;
            }

            $bestIdx = null;
            $bestKm = 0.0;
            foreach ($days as $di => $day) {
                if (($day['type'] ?? '') !== TrainingType::Easy->value) {
                    continue;
                }
                $km = (float) ($day['target_km'] ?? 0);
                if ($km > $bestKm) {
                    $bestKm = $km;
                    $bestIdx = $di;
                }
            }

            if ($bestIdx !== null && $bestKm >= self::MIN_LONG_RUN_KM) {
                $payload['schedule']['weeks'][$wi]['days'][$bestIdx]['type'] = TrainingType::LongRun->value;
            }
        }

        return $payload;
    }

    private function resolveBaselinePace(User $user): int
    {
        $profile = $user->runningProfile()->first();
        $pace = (int) ($profile?->metrics['avg_pace_seconds_per_km'] ?? 0);

        return $pace > 0 ? $pace : self::DEFAULT_BASELINE_PACE;
    }

    /**
     * Only one `long_run` per week, and it must be both (a) the longest day
     * of the week and (b) at least MIN_LONG_RUN_KM. Anything else marked
     * `long_run` is demoted to `easy`. Never auto-promotes — if the AI
     * didn't pick a long run, we don't invent one.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function reclassifyLongRuns(array $payload): array
    {
        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            $days = $week['days'] ?? [];
            if (empty($days)) {
                continue;
            }

            $maxKm = 0.0;
            $maxIdx = null;
            foreach ($days as $di => $day) {
                $km = (float) ($day['target_km'] ?? 0);
                if ($km > $maxKm) {
                    $maxKm = $km;
                    $maxIdx = $di;
                }
            }

            foreach ($days as $di => $day) {
                if (($day['type'] ?? '') !== TrainingType::LongRun->value) {
                    continue;
                }
                $isLongest = $di === $maxIdx;
                $longEnough = $maxKm >= self::MIN_LONG_RUN_KM;
                if (! $isLongest || ! $longEnough) {
                    $days[$di]['type'] = TrainingType::Easy->value;
                }
            }

            $payload['schedule']['weeks'][$wi]['days'] = $days;
        }

        return $payload;
    }

    /**
     * Fill in `target_pace_seconds_per_km` on every day that doesn't already
     * have one — purely as a baseline-relative default. Any pace the AI
     * explicitly set (including a progressive ramp toward goal pace on
     * quality days) is preserved verbatim. The agent owns progression;
     * the optimizer only backfills.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function computePaces(array $payload, int $baseline): array
    {
        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            foreach (($week['days'] ?? []) as $di => $day) {
                $type = (string) ($day['type'] ?? TrainingType::Easy->value);

                if (($day['target_pace_seconds_per_km'] ?? null) === null) {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['target_pace_seconds_per_km']
                        = $this->paceForType($baseline, $type);
                }

                if (! isset($day['intervals']) || ! is_array($day['intervals'])) {
                    continue;
                }

                foreach ($day['intervals'] as $si => $segment) {
                    if (! is_array($segment)) {
                        continue;
                    }
                    if (($segment['target_pace_seconds_per_km'] ?? null) !== null) {
                        continue;
                    }
                    $kind = (string) ($segment['kind'] ?? 'work');
                    $segPace = match ($kind) {
                        'work' => $this->paceForType($baseline, TrainingType::Interval->value),
                        'recovery' => max(150, $baseline + self::PACE_DELTA_INTERVAL_RECOVERY),
                        'warmup', 'cooldown' => $this->paceForType($baseline, TrainingType::Easy->value),
                        default => $this->paceForType($baseline, TrainingType::Easy->value),
                    };
                    $payload['schedule']['weeks'][$wi]['days'][$di]['intervals'][$si]['target_pace_seconds_per_km'] = $segPace;
                }
            }
        }

        return $payload;
    }

    private function paceForType(int $baseline, string $type): int
    {
        $delta = self::PACE_DELTAS[$type] ?? 0;

        // Floor 2:30/km so default pace can never become absurdly fast.
        return max(150, $baseline + $delta);
    }

    /**
     * Generate a deterministic human-readable title for every day that
     * doesn't already have one set. The training day whose real date
     * matches `target_date` is the race itself and gets the goal name as
     * its title, overriding whatever was previously set. All other days
     * fall through to the type label (e.g. "Easy", "Long run") — the
     * km value is rendered separately by the UI, so the title doesn't
     * need to encode it.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function generateTitles(array $payload, ?string $goalName): array
    {
        $stated = $payload['target_date'] ?? null;
        $target = (is_string($stated) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated))
            ? Carbon::parse($stated)->startOfDay()
            : null;
        $planStart = Carbon::now()->startOfWeek();

        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            $weekNum = (int) ($week['week_number'] ?? 1);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            foreach (($week['days'] ?? []) as $di => $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                $date = ($dow >= 1 && $dow <= 7)
                    ? $weekStart->copy()->addDays($dow - 1)
                    : null;

                $isRaceDay = $target !== null
                    && $date !== null
                    && $date->equalTo($target)
                    && ! empty($goalName);

                if ($isRaceDay) {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['title'] = $goalName;

                    continue;
                }

                $existing = $day['title'] ?? null;
                if (is_string($existing) && trim($existing) !== '') {
                    continue;
                }

                $payload['schedule']['weeks'][$wi]['days'][$di]['title'] = $this->dayTitle($day);
            }
        }

        return $payload;
    }

    /**
     * @param  array<string, mixed>  $day
     */
    private function dayTitle(array $day): string
    {
        $type = (string) ($day['type'] ?? TrainingType::Easy->value);

        return $this->typeName($type);
    }

    private function typeName(string $type): string
    {
        return match ($type) {
            TrainingType::Easy->value => 'Easy',
            TrainingType::Tempo->value => 'Tempo',
            TrainingType::LongRun->value => 'Long run',
            TrainingType::Interval->value => 'Intervals',
            TrainingType::Threshold->value => 'Threshold',
            default => ucfirst(str_replace('_', ' ', $type)),
        };
    }

    /**
     * Sum each week's day distances into `total_km`. Always authoritative —
     * overwrites whatever the AI emitted.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function recalculateWeeklyTotals(array $payload): array
    {
        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            $total = 0.0;
            foreach (($week['days'] ?? []) as $day) {
                $total += (float) ($day['target_km'] ?? 0);
            }
            $payload['schedule']['weeks'][$wi]['total_km'] = round($total, 1);
        }

        return $payload;
    }

    /**
     * Drop any training day whose real calendar date falls STRICTLY AFTER
     * the stated `target_date`. Runs on every optimize() call (create and
     * edit) so a Saturday tacked on after a Friday race can't survive an
     * edit pass. A no-op when target_date isn't set.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function dropDaysPastTarget(array $payload): array
    {
        $stated = $payload['target_date'] ?? null;
        if (! is_string($stated) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated)) {
            return $payload;
        }

        return $this->dropDaysAfter($payload, Carbon::parse($stated)->startOfDay());
    }

    /**
     * Set `target_date` to the calendar date of the plan's actual final
     * training day WHEN target_date is currently null. Used only on fresh
     * create_schedule calls for open-ended (no-stated-target) plans.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function alignTargetDateToLastDay(array $payload): array
    {
        $stated = $payload['target_date'] ?? null;
        if (is_string($stated) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated)) {
            return $payload;
        }

        $last = $this->findLastTrainingDate($payload);
        if ($last !== null) {
            $payload['target_date'] = $last->toDateString();
        }

        return $payload;
    }

    /**
     * Collapse duplicate day_of_week entries within the same week. The AI
     * occasionally emits the same dow twice (e.g. two dow=5 entries in
     * the race week). Keep the first occurrence; drop the rest. Runs on
     * every call so subsequent edits can't silently reintroduce dupes.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function deduplicateDaysPerWeek(array $payload): array
    {
        foreach ($payload['schedule']['weeks'] as $wi => $week) {
            $seen = [];
            $unique = [];
            foreach (($week['days'] ?? []) as $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                if (isset($seen[$dow])) {
                    continue;
                }
                $seen[$dow] = true;
                $unique[] = $day;
            }
            $payload['schedule']['weeks'][$wi]['days'] = $unique;
        }

        return $payload;
    }

    /**
     * Remove every training day whose real calendar date is strictly after
     * `$cutoff`. Drops any week that becomes empty as a result.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function dropDaysAfter(array $payload, Carbon $cutoff): array
    {
        $planStart = Carbon::now()->startOfWeek();
        $weeks = [];
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            $weekNum = (int) ($week['week_number'] ?? 1);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            $keptDays = [];
            foreach (($week['days'] ?? []) as $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                $date = $weekStart->copy()->addDays($dow - 1);
                if ($date->gt($cutoff)) {
                    continue;
                }
                $keptDays[] = $day;
            }
            if ($keptDays === []) {
                continue;
            }
            $week['days'] = $keptDays;
            $weeks[] = $week;
        }
        $payload['schedule']['weeks'] = $weeks;

        return $payload;
    }

    private function findLastTrainingDate(array $payload): ?Carbon
    {
        $planStart = Carbon::now()->startOfWeek();
        $latest = null;
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            $weekNum = (int) ($week['week_number'] ?? 1);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            foreach (($week['days'] ?? []) as $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                $date = $weekStart->copy()->addDays($dow - 1);
                if ($latest === null || $date->gt($latest)) {
                    $latest = $date;
                }
            }
        }

        return $latest;
    }

    /**
     * If a training day falls on `target_date`, force its content to the
     * goal: distance = goal distance, pace = goal pace (if goal_time_seconds
     * is set), type = `tempo` for race / PR goals. This blocks the AI from
     * leaving a 4km easy run on race day and having the UI relabel it as
     * the race — the race day is now the race, period.
     *
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    private function enforceRaceDay(array $payload): array
    {
        $stated = $payload['target_date'] ?? null;
        if (! is_string($stated) || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $stated)) {
            return $payload;
        }
        $target = Carbon::parse($stated)->startOfDay();

        $goalType = $payload['goal_type'] ?? null;
        $raceKm = PlanPayload::goalKm($payload);
        $goalTime = $payload['goal_time_seconds'] ?? null;
        $goalPace = ($raceKm !== null && is_numeric($goalTime) && (float) $goalTime > 0)
            ? (int) round((int) $goalTime / $raceKm)
            : null;

        $planStart = Carbon::now()->startOfWeek();

        foreach (($payload['schedule']['weeks'] ?? []) as $wi => $week) {
            $weekNum = (int) ($week['week_number'] ?? 1);
            $weekStart = $planStart->copy()->addWeeks($weekNum - 1);
            foreach (($week['days'] ?? []) as $di => $day) {
                $dow = (int) ($day['day_of_week'] ?? 0);
                if ($dow < 1 || $dow > 7) {
                    continue;
                }
                $date = $weekStart->copy()->addDays($dow - 1);
                if (! $date->equalTo($target)) {
                    continue;
                }

                if ($raceKm !== null) {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['target_km'] = $raceKm;
                }
                if ($goalPace !== null) {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['target_pace_seconds_per_km'] = $goalPace;
                }
                if ($goalType === 'race' || $goalType === 'pr_attempt') {
                    $payload['schedule']['weeks'][$wi]['days'][$di]['type'] = TrainingType::Tempo->value;
                }
                // Null the title so generateTitles' race-day override picks
                // up the goal_name cleanly (instead of something like
                // "Easy taper run with strides" surviving).
                $payload['schedule']['weeks'][$wi]['days'][$di]['title'] = null;
            }
        }

        return $payload;
    }
}
