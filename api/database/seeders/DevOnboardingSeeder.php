<?php

namespace Database\Seeders;

use App\Enums\HeartRateZonesSource;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\PlanGeneration;
use App\Models\User;
use App\Models\UserNotification;
use App\Models\UserRunningProfile;
use App\Models\WearableActivity;
use App\Support\HeartRateZoneDeriver;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

/**
 * Local-only sample data that drops the dev-login user (the oldest user —
 * same one `AuthController::devLogin` returns) into a fresh pre-onboarding
 * state with realistic 12-month run history + age-derived HR zones.
 *
 * Result: when you run `bash app/scripts/run-dev.sh`, the dev user is
 * already signed in but lands on `/onboarding/connect-health`, and the
 * downstream `/onboarding/overview` screen shows real metrics + AI
 * narrative computed off the seeded activities.
 *
 * Idempotent: every run wipes prior dev-onboarding state (activities
 * tagged with our prefix, goals, plan generations, proposals, running
 * profile cache, notifications) and rebuilds.
 */
class DevOnboardingSeeder extends Seeder
{
    private const SEED_ACTIVITY_PREFIX = 'dev-onb-seed-';

    /** Mid-2002 → age 23 today (deterministic regardless of when you re-seed). */
    private const DOB = '2002-06-15';

    public function run(): void
    {
        if (! app()->environment('local')) {
            return;
        }

        $user = User::orderBy('id')->first();
        if ($user === null) {
            $this->command?->warn('DevOnboardingSeeder: no user found — run AdminUserSeeder first.');

            return;
        }

        $this->resetUserToPreOnboarding($user);
        $this->seedDateOfBirth($user);
        $this->seedActivities($user);
        $this->seedHeartRateZones($user);

        $this->command?->info(sprintf(
            'DevOnboardingSeeder: %s now on pre-onboarding state — DOB %s, %d activities, age-derived HR zones.',
            $user->email,
            self::DOB,
            WearableActivity::where('user_id', $user->id)->count(),
        ));
    }

    private function resetUserToPreOnboarding(User $user): void
    {
        // Wipe anything that would short-circuit the onboarding redirect.
        Goal::where('user_id', $user->id)->delete();
        PlanGeneration::where('user_id', $user->id)->delete();
        CoachProposal::where('user_id', $user->id)->delete();
        UserNotification::where('user_id', $user->id)->delete();
        UserRunningProfile::where('user_id', $user->id)->delete();

        // Wipe any prior dev-onboarding wearable rows + any dev-plan rows
        // (so re-seeding from a previous DevPlanSeeder run leaves a clean
        // slate). Real ingestion rows from a physical device stay put.
        WearableActivity::where('user_id', $user->id)
            ->where(function ($q) {
                $q->where('source_activity_id', 'like', self::SEED_ACTIVITY_PREFIX.'%')
                    ->orWhere('source_activity_id', 'like', 'dev-seed-%');
            })
            ->delete();

        $user->forceFill([
            'has_completed_onboarding' => false,
            'heart_rate_zones' => null,
            'heart_rate_zones_source' => HeartRateZonesSource::Default,
            'personal_records' => null,
        ])->save();
    }

    private function seedDateOfBirth(User $user): void
    {
        $user->forceFill(['date_of_birth' => self::DOB])->save();
    }

    /**
     * Seed ~80 running workouts over the last 365 days. Volume + intensity
     * mix ramps up over the year so the profile narrative reads like
     * someone who's been training consistently:
     *   - months -12..-8: base building, 1-2 easy runs/week, 4-7 km
     *   - months -8..-4: 2-3 runs/week, easy + occasional long up to 14 km
     *   - months -4..now: 2-3 runs/week, adds tempos + 12-20 km long runs
     *
     * Deterministic via mt_srand seed → same dev experience every reset.
     */
    private function seedActivities(User $user): void
    {
        mt_srand(202206);

        $today = Carbon::today();
        $rows = [];
        $counter = 0;

        for ($daysAgo = 365; $daysAgo >= 1; $daysAgo--) {
            $date = $today->copy()->subDays($daysAgo);
            $phase = match (true) {
                $daysAgo > 240 => 'base',
                $daysAgo > 120 => 'mid',
                default => 'sharpen',
            };

            $shouldRun = $this->shouldRunOnDay($date, $phase);
            if (! $shouldRun) {
                continue;
            }

            $session = $this->sessionForPhase($phase, $date);

            $startedAt = $date->copy()->setTime($session['hour'], $session['minute']);
            $durationSec = (int) round($session['km'] * $session['paceSecPerKm']);

            $rows[] = [
                'user_id' => $user->id,
                'source' => 'apple_health',
                'source_activity_id' => self::SEED_ACTIVITY_PREFIX.($counter++),
                'source_user_id' => null,
                'type' => 'Run',
                'name' => $session['name'],
                'distance_meters' => (int) round($session['km'] * 1000),
                'duration_seconds' => $durationSec,
                'elapsed_seconds' => $durationSec,
                'average_pace_seconds_per_km' => $session['paceSecPerKm'],
                'average_heartrate' => $session['hr'],
                'max_heartrate' => $session['hr'] + $session['hrSpread'],
                'elevation_gain_meters' => $session['elevationM'],
                'calories_kcal' => (int) round($session['km'] * 65),
                'start_date' => $startedAt,
                'end_date' => $startedAt->copy()->addSeconds($durationSec),
                'raw_data' => json_encode([]),
                'synced_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ];
        }

        // Bulk insert — ~80 rows so the overview narrative has signal to
        // work with. Individual create() would dispatch ProcessWearable
        // jobs we don't want firing in the seeder.
        foreach (array_chunk($rows, 200) as $chunk) {
            WearableActivity::insert($chunk);
        }
    }

    private function shouldRunOnDay(Carbon $date, string $phase): bool
    {
        // Skip a deterministic-ish set of days to land near ~2 runs/week
        // and avoid making it look mechanical (every Mon/Wed/Sat).
        $dow = $date->dayOfWeek; // 0=Sun..6=Sat

        $weeklyTargets = match ($phase) {
            'base' => [1, 4, 6],            // Mon, Thu, Sat ~1-2x/wk after skips
            'mid' => [1, 3, 5, 6],          // Mon, Wed, Fri, Sat
            'sharpen' => [1, 3, 5, 6],      // Mon, Wed, Fri, Sat (long run)
        };

        if (! in_array($dow, $weeklyTargets, true)) {
            return false;
        }

        // Drop ~25% of candidate days for natural variation (skipped runs,
        // travel weeks, weather, recovery).
        return mt_rand(0, 99) >= 25;
    }

    /**
     * @return array{name: string, km: float, paceSecPerKm: int, hr: int, hrSpread: int, hour: int, minute: int, elevationM: int|null}
     */
    private function sessionForPhase(string $phase, Carbon $date): array
    {
        $dow = $date->dayOfWeek;
        $isWeekend = $dow === 6 || $dow === 0;

        // Long run on Saturdays in mid + sharpen phases.
        $isLongRun = $isWeekend && in_array($phase, ['mid', 'sharpen'], true) && mt_rand(0, 99) < 75;

        // Tempos: only in sharpen phase, midweek, ~30% of weekday runs.
        $isTempo = $phase === 'sharpen' && ! $isWeekend && mt_rand(0, 99) < 30;

        if ($isLongRun) {
            $km = match ($phase) {
                'mid' => $this->randFloat(10.0, 14.0),
                default => $this->randFloat(12.0, 20.0),
            };
            $paceSec = mt_rand(330, 390);   // 5:30 - 6:30/km
            $hr = mt_rand(142, 158);

            return [
                'name' => 'Long run',
                'km' => round($km, 1),
                'paceSecPerKm' => $paceSec,
                'hr' => $hr,
                'hrSpread' => mt_rand(8, 16),
                'hour' => 8,
                'minute' => mt_rand(0, 45),
                'elevationM' => mt_rand(40, 220),
            ];
        }

        if ($isTempo) {
            $km = $this->randFloat(6.0, 10.0);
            $paceSec = mt_rand(265, 300);    // 4:25 - 5:00/km
            $hr = mt_rand(162, 176);

            return [
                'name' => 'Tempo run',
                'km' => round($km, 1),
                'paceSecPerKm' => $paceSec,
                'hr' => $hr,
                'hrSpread' => mt_rand(10, 18),
                'hour' => 18,
                'minute' => mt_rand(0, 50),
                'elevationM' => mt_rand(20, 80),
            ];
        }

        // Easy run — the bulk of weekly volume.
        $kmRange = match ($phase) {
            'base' => [4.0, 7.0],
            'mid' => [5.0, 9.0],
            default => [5.0, 10.0],
        };
        $km = $this->randFloat($kmRange[0], $kmRange[1]);
        $paceSec = mt_rand(340, 410);   // 5:40 - 6:50/km
        $hr = mt_rand(132, 150);

        return [
            'name' => 'Easy run',
            'km' => round($km, 1),
            'paceSecPerKm' => $paceSec,
            'hr' => $hr,
            'hrSpread' => mt_rand(6, 14),
            'hour' => $isWeekend ? 9 : 7,
            'minute' => mt_rand(0, 55),
            'elevationM' => mt_rand(20, 120),
        ];
    }

    /**
     * Run the same derivation the onboarding zones endpoint runs — Tanaka
     * prior from DOB, no resting HR (HealthKit isn't available in dev),
     * with upward correction based on the seeded max_heartrate values. So
     * the zones screen subtitle copy ("source: derived_age") + the
     * /onboarding/overview HR metrics both line up with what a real
     * iPhone-connected user would see.
     */
    private function seedHeartRateZones(User $user): void
    {
        $user->refresh();   // pick up the freshly seeded date_of_birth
        $deriver = app(HeartRateZoneDeriver::class);
        $age = Carbon::parse(self::DOB)->age;

        $result = $deriver->derive($user, $age, restingHeartRate: null);

        $user->forceFill([
            'heart_rate_zones' => $result->zones,
            'heart_rate_zones_source' => HeartRateZonesSource::DerivedAge,
        ])->save();
    }

    private function randFloat(float $min, float $max): float
    {
        return $min + (mt_rand() / mt_getrandmax()) * ($max - $min);
    }
}
