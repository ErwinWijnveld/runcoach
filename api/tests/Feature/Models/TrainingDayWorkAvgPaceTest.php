<?php

namespace Tests\Feature\Models;

use App\Enums\TrainingType;
use App\Models\TrainingDay;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingDayWorkAvgPaceTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * @param  list<array<string,mixed>>  $steps
     * @return array<string,mixed>
     */
    private function grouped(array $steps): array
    {
        return ['warmup_seconds' => 60, 'steps' => $steps, 'cooldown_seconds' => 300];
    }

    public function test_returns_null_for_non_interval_day(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Tempo,
            'intervals_json' => $this->grouped([
                ['type' => 'block', 'reps' => 1, 'work_distance_m' => 1000, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
            ]),
        ]);

        // Even with intervals_json populated, a non-interval type returns
        // null — this accessor is strictly for interval sessions.
        $this->assertNull($day->workSetAveragePaceSecondsPerKm());
    }

    public function test_returns_null_when_intervals_missing(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => null,
        ]);

        $this->assertNull($day->workSetAveragePaceSecondsPerKm());
    }

    public function test_returns_null_when_no_work_step_has_pace(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->grouped([
                ['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => null, 'recovery_seconds' => 90],
            ]),
        ]);

        $this->assertNull($day->workSetAveragePaceSecondsPerKm());
    }

    public function test_averages_uniform_work_paces(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->grouped([
                ['type' => 'block', 'reps' => 3, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
            ]),
        ]);

        $this->assertSame(270, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_averages_across_distinct_blocks(): void
    {
        // Per-step mean: 270 + 280 + 270 = 820 / 3 = 273.33 → 273.
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->grouped([
                ['type' => 'block', 'reps' => 1, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
                ['type' => 'block', 'reps' => 1, 'work_distance_m' => 800, 'work_pace_seconds_per_km' => 280, 'recovery_seconds' => 90],
                ['type' => 'rep', 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 270],
            ]),
        ]);

        $this->assertSame(273, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_rest_steps_do_not_contribute_to_average(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->grouped([
                ['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
                ['type' => 'rest', 'duration_seconds' => 120],
            ]),
        ]);

        // Only the work step counts; the standalone rest is ignored.
        $this->assertSame(270, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_skips_work_steps_with_invalid_pace(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->grouped([
                ['type' => 'rep', 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 0],
                ['type' => 'rep', 'work_distance_m' => 400, 'work_pace_seconds_per_km' => -10],
                ['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 280, 'recovery_seconds' => 90],
            ]),
        ]);

        // 0 and -10 are dropped to null by normalization; only 280 remains.
        $this->assertSame(280, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_tolerates_legacy_flat_rows(): void
    {
        // Rows written before the grouped migration are still readable —
        // the accessor folds them via IntervalBlueprint::normalize.
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'warmup', 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'cooldown', 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
            ],
        ]);

        $this->assertSame(270, $day->workSetAveragePaceSecondsPerKm());
    }
}
