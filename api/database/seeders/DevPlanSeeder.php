<?php

namespace Database\Seeders;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\WearableActivity;
use App\Services\ComplianceScoringService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

/**
 * Local-only sample data for the dev-login user (the oldest user — same
 * one `AuthController::devLogin` returns). Creates an 8-week half-marathon
 * plan with week 1 starting the Monday before today, so:
 *   - past days in week 1 already have completed results + wearable activity + AI feedback
 *   - today / upcoming days are still ungated for testing the workout agent's edit/reschedule flows
 *
 * Idempotent: every run wipes any prior dev-seed goal + wearable activity
 * (matched on the deterministic `source_activity_id` prefix) and rebuilds.
 */
class DevPlanSeeder extends Seeder
{
    private const SEED_GOAL_NAME = 'Dev Half Marathon';

    private const SEED_ACTIVITY_PREFIX = 'dev-seed-';

    public function run(): void
    {
        if (! app()->environment('local')) {
            return;
        }

        $user = User::orderBy('id')->first();
        if ($user === null) {
            $this->command?->warn('DevPlanSeeder: no user found — run AdminUserSeeder first.');

            return;
        }

        $this->wipePriorDevSeed($user);

        $weekStart = Carbon::now()->startOfWeek()->subWeek();
        $totalWeeks = 8;

        $goal = Goal::create([
            'user_id' => $user->id,
            'type' => GoalType::Race->value,
            'name' => self::SEED_GOAL_NAME,
            'distance' => GoalDistance::HalfMarathon->value,
            'goal_time_seconds' => 6300,
            'target_date' => $weekStart->copy()->addWeeks($totalWeeks - 1)->endOfWeek()->toDateString(),
            'status' => GoalStatus::Active->value,
        ]);

        for ($w = 1; $w <= $totalWeeks; $w++) {
            $weekStartsAt = $weekStart->copy()->addWeeks($w - 1);
            $week = TrainingWeek::create([
                'goal_id' => $goal->id,
                'week_number' => $w,
                'starts_at' => $weekStartsAt->toDateString(),
                'total_km' => $this->weeklyKm($w),
                'focus' => $this->weeklyFocus($w, $totalWeeks),
                'coach_notes' => null,
            ]);

            foreach ($this->daysForWeek($w, $totalWeeks) as $dayPlan) {
                $dayDate = $weekStartsAt->copy()->addDays($dayPlan['day_of_week'] - 1);
                $day = TrainingDay::create([
                    'training_week_id' => $week->id,
                    'date' => $dayDate->toDateString(),
                    'order' => $dayPlan['day_of_week'],
                    'type' => $dayPlan['type'],
                    'title' => $dayPlan['title'],
                    'description' => $dayPlan['description'] ?? null,
                    'target_km' => $dayPlan['target_km'],
                    'target_pace_seconds_per_km' => $dayPlan['target_pace_seconds_per_km'],
                    'target_heart_rate_zone' => $dayPlan['target_heart_rate_zone'] ?? null,
                    'intervals_json' => $dayPlan['intervals_json'] ?? null,
                ]);

                if ($dayDate->lt(Carbon::now()->startOfDay())) {
                    $this->logCompletedRun($user, $day, $dayPlan, $dayDate);
                }
            }
        }

        $this->seedUnmatchedActivities($user);
        $this->seedPaceAdjustmentNotification($user);

        $this->command?->info(sprintf(
            'DevPlanSeeder: seeded "%s" for %s (week 1 starts %s, race day %s).',
            self::SEED_GOAL_NAME,
            $user->email,
            $weekStart->toDateString(),
            $goal->target_date->toDateString(),
        ));
    }

    /**
     * Standalone wearable activities that AREN'T linked to a TrainingDay —
     * simulates "ingested but not yet matched" runs (e.g. the user did a
     * shakeout on a rest day, an off-plan interval session at the track,
     * or a cross-train run alongside the plan). Useful for the schedule
     * UI's `available-activities` flow (window: `day.date ± 7d`) + the
     * dashboard recent-runs strip.
     *
     * Anchored to relative days-from-today so they ALWAYS sit inside the
     * picker window for any upcoming day within the next ~5 days, no
     * matter what weekday the seeder runs on. Placed on plan rest-days
     * (Tue/Thu/Sun) so they can't accidentally collide with a planned run.
     *
     * Includes one interval-shape activity (full-run avg pace much slower
     * than the work pace would suggest, because it mixes warmup + work +
     * recovery + cooldown) so the activity-picker UI has a realistic
     * interval session to render.
     */
    private function seedUnmatchedActivities(User $user): void
    {
        $samples = [
            // Easy lunch jog
            ['days_ago' => 5, 'hour' => 12, 'name' => 'Lunch break run', 'km' => 4.2, 'pace' => 380, 'hr' => 138],
            // Faster aerobic pickup
            ['days_ago' => 3, 'hour' => 7, 'name' => 'Morning shakeout', 'km' => 6.5, 'pace' => 340, 'hr' => 152],
            // Sunday off-plan track session — 5×600m: full-run avg ≈ 5:08/km
            // (work pace ~4:30 mixed with 90s recoveries + warmup + cooldown).
            // HR sits high because reps push toward Z4-Z5.
            ['days_ago' => 1, 'hour' => 17, 'name' => 'Track session 5×600m', 'km' => 5.3, 'pace' => 308, 'hr' => 168],
            // Today's relaxed weekend cruise
            ['days_ago' => 0, 'hour' => 9, 'name' => 'Weekend cruise', 'km' => 8.0, 'pace' => 365, 'hr' => 145],
        ];

        foreach ($samples as $i => $s) {
            $startedAt = Carbon::now()
                ->subDays($s['days_ago'])
                ->setTime($s['hour'], 15);

            if ($startedAt->gt(Carbon::now())) {
                continue;
            }

            $duration = (int) round($s['km'] * $s['pace']);

            WearableActivity::create([
                'user_id' => $user->id,
                'source' => 'apple_health',
                'source_activity_id' => self::SEED_ACTIVITY_PREFIX.'unmatched-'.$i,
                'source_user_id' => null,
                'type' => 'Run',
                'name' => $s['name'],
                'distance_meters' => (int) round($s['km'] * 1000),
                'duration_seconds' => $duration,
                'elapsed_seconds' => $duration,
                'average_pace_seconds_per_km' => $s['pace'],
                'average_heartrate' => $s['hr'],
                'max_heartrate' => $s['hr'] + 12,
                'elevation_gain_meters' => null,
                'calories_kcal' => (int) round($s['km'] * 65),
                'start_date' => $startedAt,
                'end_date' => $startedAt->copy()->addSeconds($duration),
                'raw_data' => [],
                'synced_at' => now(),
            ]);
        }
    }

    /**
     * Drop a sample "your easy runs are too hard" suggestion in the inbox so
     * the bell badge + boot popup have something to show in dev. Mirrors what
     * `PaceAdjustmentEvaluator` would emit after a real run came back with HR
     * well above the planned zone.
     */
    private function seedPaceAdjustmentNotification(User $user): void
    {
        $sourceResult = TrainingResult::query()
            ->whereHas(
                'trainingDay',
                fn ($q) => $q->where('type', TrainingType::Easy->value)
                    ->whereHas('trainingWeek.goal', fn ($g) => $g->where('user_id', $user->id))
            )
            ->latest('id')
            ->first();

        UserNotification::create([
            'user_id' => $user->id,
            'type' => UserNotification::TYPE_PACE_ADJUSTMENT,
            'title' => 'Your Easy runs are too hard',
            'body' => 'Your heart rate sat outside the planned zone — try slowing every upcoming easy run by +25s/km.',
            'action_data' => [
                'source_training_result_id' => $sourceResult?->id,
                'training_type' => TrainingType::Easy->value,
                'pace_factor' => 1.07,
            ],
            'status' => UserNotification::STATUS_PENDING,
        ]);
    }

    private function wipePriorDevSeed(User $user): void
    {
        // Cascade chain: goal → weeks → days → results, so the goal delete
        // wipes everything plan-side. Wearables we tag with our prefix so
        // we can scrub them without touching real ingestion data.
        Goal::where('user_id', $user->id)->where('name', self::SEED_GOAL_NAME)->delete();

        WearableActivity::where('user_id', $user->id)
            ->where('source_activity_id', 'like', self::SEED_ACTIVITY_PREFIX.'%')
            ->delete();

        UserNotification::where('user_id', $user->id)
            ->where('type', UserNotification::TYPE_PACE_ADJUSTMENT)
            ->delete();
    }

    /**
     * @param  array<string, mixed>  $dayPlan
     */
    private function logCompletedRun(User $user, TrainingDay $day, array $dayPlan, Carbon $dayDate): void
    {
        $isInterval = $dayPlan['type'] === TrainingType::Interval->value;

        // Pulled toward the target with a small ± so the compliance scorer
        // returns realistic numbers and the workout-agent context shows
        // genuinely useful actuals (not perfect, not disastrous).
        $actualKmFloat = max(2.0, $dayPlan['target_km'] + $this->jitter(-0.6, 0.6));

        // Interval-session full-run avg pace mixes work + recovery + warmup
        // + cooldown — naturally far slower than the work-set target. We
        // anchor at ~5:20-5:40/km regardless of the work pace so the seeded
        // data looks like a real synced interval workout (which the new
        // scorer will pace-score = null).
        $targetPace = $isInterval ? 320 : ($dayPlan['target_pace_seconds_per_km'] ?? 300);
        $actualPace = max(180, $targetPace + (int) $this->jitter(-15, 18));

        // HR profile by type:
        //  - long runs: not always recorded (some watches don't capture)
        //  - intervals: avg sits high — work peaks ≈180, recovery ≈140,
        //    full-run avg ≈ 160-170
        //  - everything else: aerobic mid-zone, ≈145
        $actualHr = match (true) {
            $dayPlan['type'] === TrainingType::LongRun->value => null,
            $isInterval => 162 + (int) $this->jitter(-6, 8),
            default => 145 + (int) $this->jitter(-8, 12),
        };

        $startedAt = $dayDate->copy()->setTime(7, 30);
        $duration = (int) round(($actualKmFloat) * $actualPace);

        $activity = WearableActivity::create([
            'user_id' => $user->id,
            'source' => 'apple_health',
            'source_activity_id' => self::SEED_ACTIVITY_PREFIX.$day->id,
            'source_user_id' => null,
            'type' => 'Run',
            'name' => $dayPlan['title'],
            'distance_meters' => (int) round($actualKmFloat * 1000),
            'duration_seconds' => $duration,
            'elapsed_seconds' => $duration,
            'average_pace_seconds_per_km' => $actualPace,
            'average_heartrate' => $actualHr,
            'max_heartrate' => $actualHr !== null ? $actualHr + 12 : null,
            'elevation_gain_meters' => null,
            'calories_kcal' => (int) round($actualKmFloat * 65),
            'start_date' => $startedAt,
            'end_date' => $startedAt->copy()->addSeconds($duration),
            'raw_data' => [],
            'synced_at' => now(),
        ]);

        $distScore = $this->complianceScore($actualKmFloat, (float) $dayPlan['target_km'], 0.6);
        $hrScore = $actualHr === null ? null : 7.5 + $this->jitter(-1.5, 1.5);

        // Pace score is null on interval days — the live scorer mirrors
        // this. Re-uses `ComplianceScoringService::weightedOverall` (the
        // single source of truth) so seeded dashboard numbers exactly
        // match what the live scorer would produce.
        $paceScore = $isInterval ? null : $this->complianceScore($actualPace, (float) $targetPace, 25.0);
        $compliance = ComplianceScoringService::weightedOverall($distScore, $paceScore, $hrScore);

        TrainingResult::create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
            'compliance_score' => round($compliance, 1),
            'actual_km' => round($actualKmFloat, 1),
            'actual_pace_seconds_per_km' => $actualPace,
            'actual_avg_heart_rate' => $actualHr,
            'pace_score' => $paceScore !== null ? round($paceScore, 1) : null,
            'distance_score' => round($distScore, 1),
            'heart_rate_score' => $hrScore === null ? null : round($hrScore, 1),
            'ai_feedback' => $this->fakeFeedback($dayPlan, $actualKmFloat, $actualPace, $compliance, $targetPace),
            'matched_at' => $startedAt->copy()->addSeconds($duration + 30),
        ]);
    }

    private function complianceScore(float $actual, float $target, float $tolerance): float
    {
        if ($target <= 0) {
            return 8.0;
        }
        $delta = abs($actual - $target);
        $score = 10.0 - ($delta / $tolerance) * 1.5;

        return max(2.0, min(10.0, $score));
    }

    /**
     * Mirrors the real `ActivityFeedbackAgent` shape: a bolded one-sentence
     * verdict followed by 1-3 sentences of detail. No headings, no bullets,
     * no em-dashes — same constraints the live agent operates under, so the
     * seeded data renders identically in the schedule UI.
     */
    private function fakeFeedback(array $dayPlan, float $actualKm, int $actualPace, float $compliance, int $targetPace): string
    {
        $paceMin = intdiv($actualPace, 60);
        $paceSec = str_pad((string) ($actualPace % 60), 2, '0', STR_PAD_LEFT);
        $paceFmt = "{$paceMin}:{$paceSec}/km";
        $kmFmt = $this->fmtKm($actualKm);
        $paceDelta = $actualPace - $targetPace;
        $type = $dayPlan['type'];

        if ($compliance >= 8.5) {
            $headline = match ($type) {
                TrainingType::LongRun->value => '**Strong long run, paced beautifully from start to finish.**',
                TrainingType::Tempo->value => '**Sharp tempo execution, right at goal pace.**',
                TrainingType::Interval->value => '**Reps were crisp and consistent across the set.**',
                default => '**Easy day done well, exactly the recovery you needed.**',
            };
            $detail = "You covered {$kmFmt} at {$paceFmt}, holding effort steady throughout. HR sat in the right zone the whole way, which means you can trust this fitness going into the next block.";
        } elseif ($compliance >= 7.0) {
            $direction = $paceDelta > 0 ? 'a touch slower than planned' : 'a touch quicker than planned';
            $headline = "**Solid {$type} session, {$direction} but right where it counts.**";
            $detail = "You ran {$kmFmt} at {$paceFmt}. The split is close enough to plan that no adjustment is needed; keep the pattern going next week.";
        } elseif ($compliance >= 5.5) {
            $headline = '**Mixed result on this one, useful data either way.**';
            $detail = $paceDelta > 0
                ? "You finished {$kmFmt} at {$paceFmt}, drifting slower than the {$this->paceLabel($targetPace)} target. Could be fatigue, could be heat. If next easy day still feels heavy, take an extra rest day."
                : "You finished {$kmFmt} at {$paceFmt}, faster than the {$this->paceLabel($targetPace)} target. Common for fresh legs, but watch the cumulative load this week.";
        } else {
            $headline = '**Tough one, but every plan has these days.**';
            $detail = "You logged {$kmFmt} at {$paceFmt} versus a {$this->paceLabel($targetPace)} target. Not a red flag on its own, but worth noting if it repeats. Easy week ahead is well-timed.";
        }

        return $headline.' '.$detail;
    }

    private function paceLabel(int $secondsPerKm): string
    {
        $min = intdiv($secondsPerKm, 60);
        $sec = str_pad((string) ($secondsPerKm % 60), 2, '0', STR_PAD_LEFT);

        return "{$min}:{$sec}/km";
    }

    private function fmtKm(float $km): string
    {
        return rtrim(rtrim(number_format($km, 1, '.', ''), '0'), '.').'km';
    }

    private function jitter(float $min, float $max): float
    {
        return $min + (mt_rand() / mt_getrandmax()) * ($max - $min);
    }

    private function weeklyKm(int $week): float
    {
        return [0, 26.0, 30.0, 34.0, 28.0, 38.0, 42.0, 30.0, 22.0][$week] ?? 26.0;
    }

    private function weeklyFocus(int $week, int $total): string
    {
        if ($week === 1) {
            return 'base';
        }
        if ($week === 4) {
            return 'cutback';
        }
        if ($week >= $total - 1) {
            return 'taper';
        }

        return 'build';
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function daysForWeek(int $week, int $total): array
    {
        $longRunKm = [0, 10.0, 12.0, 14.0, 11.0, 16.0, 18.0, 14.0, 10.0][$week] ?? 12.0;
        $tempoKm = [0, 5.0, 6.0, 6.0, 5.0, 7.0, 8.0, 6.0, 5.0][$week] ?? 6.0;

        // Intervals on weeks 2 + 4. Different structures per week so the
        // parser/UI/optimizer get exercised on multiple shapes:
        //   - week 2 (past) → 6×400m @ 4:30 — short reps, 90s recovery
        //   - week 4 (upcoming) → 5×800m @ 4:40 — longer reps, 120s recovery
        // Week 2 has a matched activity + result; week 4 is planned only.
        $intervalShape = match ($week) {
            2 => ['reps' => 6, 'distance_m' => 400, 'pace' => 270, 'recovery_s' => 90, 'title' => '6×400m intervals'],
            4 => ['reps' => 5, 'distance_m' => 800, 'pace' => 280, 'recovery_s' => 120, 'title' => '5×800m intervals'],
            default => null,
        };
        $isIntervalWeek = $intervalShape !== null;

        $days = [
            [
                'day_of_week' => 1,
                'type' => TrainingType::Easy->value,
                'title' => 'Easy shakeout',
                'target_km' => 5.0,
                'target_pace_seconds_per_km' => 360,
                'target_heart_rate_zone' => 2,
                'description' => 'Conversational pace, recover from the weekend long run.',
            ],
            [
                'day_of_week' => 3,
                'type' => $isIntervalWeek ? TrainingType::Interval->value : TrainingType::Tempo->value,
                'title' => $isIntervalWeek ? $intervalShape['title'] : 'Tempo run',
                'target_km' => $tempoKm,
                'target_pace_seconds_per_km' => $isIntervalWeek ? null : 285,
                'target_heart_rate_zone' => $isIntervalWeek ? 4 : 3,
                'description' => $isIntervalWeek
                    ? 'Track-style intervals. Recover fully between reps; sharp neuromuscular work mid-block.'
                    : 'Sustained tempo at ~half marathon goal pace + 10s.',
                'intervals_json' => $isIntervalWeek
                    ? $this->buildIntervals(
                        reps: $intervalShape['reps'],
                        distanceM: $intervalShape['distance_m'],
                        paceSecPerKm: $intervalShape['pace'],
                        recoverySec: $intervalShape['recovery_s'],
                    )
                    : null,
            ],
            [
                'day_of_week' => 5,
                'type' => TrainingType::Easy->value,
                'title' => 'Easy run',
                'target_km' => 5.0,
                'target_pace_seconds_per_km' => 360,
                'target_heart_rate_zone' => 2,
                'description' => 'Easy aerobic. If legs feel heavy, cut short.',
            ],
            [
                'day_of_week' => 6,
                'type' => TrainingType::LongRun->value,
                'title' => 'Long run',
                'target_km' => $longRunKm,
                'target_pace_seconds_per_km' => 390,
                'target_heart_rate_zone' => 2,
                'description' => 'Time on feet — keep it conversational the whole way.',
            ],
        ];

        // Race day on the very last day of the final week.
        if ($week === $total) {
            $days[] = [
                'day_of_week' => 7,
                'type' => TrainingType::Tempo->value,
                'title' => self::SEED_GOAL_NAME,
                'target_km' => 21.1,
                'target_pace_seconds_per_km' => 298,
                'target_heart_rate_zone' => 4,
                'description' => 'Race day. Trust the work — start steady, finish strong.',
            ];
        }

        return $days;
    }

    /**
     * Build a canonical intervals_json segment list:
     *   warmup → reps × (work + recovery) → cooldown
     *
     * Mirrors what `PlanOptimizerService::normalizeIntervals` produces so
     * seeded data is indistinguishable from agent-generated data.
     *
     * @return list<array<string, mixed>>
     */
    private function buildIntervals(
        int $reps,
        int $distanceM,
        int $paceSecPerKm,
        int $recoverySec,
        int $warmupSec = 60,
        int $cooldownSec = 300,
    ): array {
        $segments = [
            ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => null, 'duration_seconds' => $warmupSec, 'target_pace_seconds_per_km' => null],
        ];

        for ($i = 0; $i < $reps; $i++) {
            $segments[] = [
                'kind' => 'work',
                'label' => "{$distanceM}m rep",
                'distance_m' => $distanceM,
                'duration_seconds' => null,
                'target_pace_seconds_per_km' => $paceSecPerKm,
            ];
            $segments[] = [
                'kind' => 'recovery',
                'label' => 'Recovery',
                'distance_m' => null,
                'duration_seconds' => $recoverySec,
                'target_pace_seconds_per_km' => null,
            ];
        }

        $segments[] = ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => null, 'duration_seconds' => $cooldownSec, 'target_pace_seconds_per_km' => null];

        return $segments;
    }
}
