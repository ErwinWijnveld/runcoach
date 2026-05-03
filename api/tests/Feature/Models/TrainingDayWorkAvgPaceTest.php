<?php

namespace Tests\Feature\Models;

use App\Enums\TrainingType;
use App\Models\TrainingDay;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingDayWorkAvgPaceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_null_for_non_interval_day(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Tempo,
            'intervals_json' => [
                ['kind' => 'work', 'distance_m' => 1000, 'target_pace_seconds_per_km' => 270],
            ],
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

    public function test_returns_null_when_no_work_segment_has_pace(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'warmup', 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => null],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'cooldown', 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
            ],
        ]);

        $this->assertNull($day->workSetAveragePaceSecondsPerKm());
    }

    public function test_averages_uniform_work_paces(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'warmup', 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'cooldown', 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
            ],
        ]);

        $this->assertSame(270, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_averages_pyramid_with_varying_paces(): void
    {
        // 270 + 280 + 270 = 820 / 3 = 273.33 → rounded to 273
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 800, 'target_pace_seconds_per_km' => 280],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
            ],
        ]);

        $this->assertSame(273, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_ignores_recovery_warmup_cooldown_paces_in_average(): void
    {
        // Recovery has a pace too (some sources do that). It must NOT
        // contribute — only `kind=work` segments count.
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'warmup', 'duration_seconds' => 60, 'target_pace_seconds_per_km' => 420],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 270],
                ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => 360],
                ['kind' => 'cooldown', 'duration_seconds' => 300, 'target_pace_seconds_per_km' => 420],
            ],
        ]);

        // Only the 270 work segment counts.
        $this->assertSame(270, $day->workSetAveragePaceSecondsPerKm());
    }

    public function test_skips_work_segments_with_invalid_pace(): void
    {
        $day = TrainingDay::factory()->make([
            'type' => TrainingType::Interval,
            'intervals_json' => [
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 0],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => -10],
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => '300'], // string
                ['kind' => 'work', 'distance_m' => 400, 'target_pace_seconds_per_km' => 280],
            ],
        ]);

        // Only the int 280 is valid (0/-10 invalid; '300' rejected because
        // we strict-check for int — JSON casts may surface stringified pace
        // values from edits, and we'd rather under-count than poison the
        // average with an unsanitised value).
        $this->assertSame(280, $day->workSetAveragePaceSecondsPerKm());
    }
}
