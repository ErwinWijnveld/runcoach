<?php

namespace Tests\Feature\Models;

use App\Enums\TrainingType;
use App\Models\TrainingDay;
use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

/**
 * The interval-distance invariant at the row level: after ANY save of an
 * interval-type TrainingDay that carries a blueprint, `target_km` equals
 * `IntervalBlueprint::estimateTotalKm(intervals_json)` — no matter what the
 * writer (Filament coach editor, ProposalService, a future controller) put
 * in the attribute. Spec: docs/superpowers/specs/2026-06-10-interval-target-km-recompute.md.
 */
class TrainingDayTargetKmRecomputeTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * @return array<string,mixed>
     */
    private function blueprint(int $reps = 4, int $distanceM = 800, int $pace = 270): array
    {
        return [
            'warmup_seconds' => 60,
            'steps' => [[
                'type' => 'block',
                'reps' => $reps,
                'work_distance_m' => $distanceM,
                'work_duration_seconds' => null,
                'work_pace_seconds_per_km' => $pace,
                'recovery_seconds' => 90,
            ]],
            'cooldown_seconds' => 300,
        ];
    }

    public function test_create_derives_target_km_from_blueprint(): void
    {
        $blueprint = $this->blueprint();

        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Interval,
            'target_km' => 12.0, // writer's claim, must lose
            'intervals_json' => $blueprint,
        ]);

        $this->assertSame(
            IntervalBlueprint::estimateTotalKm($blueprint),
            (float) $day->fresh()->target_km,
        );
    }

    public function test_editing_blueprint_recomputes_target_km(): void
    {
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->blueprint(reps: 4, distanceM: 400),
        ]);
        $before = (float) $day->fresh()->target_km;

        $day->update(['intervals_json' => $this->blueprint(reps: 6, distanceM: 1000)]);
        $after = (float) $day->fresh()->target_km;

        $this->assertGreaterThan($before, $after);
        $this->assertSame(
            IntervalBlueprint::estimateTotalKm($this->blueprint(reps: 6, distanceM: 1000)),
            $after,
        );
    }

    public function test_manual_target_km_edit_on_interval_day_is_overridden(): void
    {
        $blueprint = $this->blueprint();
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Interval,
            'intervals_json' => $blueprint,
        ]);

        $day->update(['target_km' => 99.0]);

        $this->assertSame(
            IntervalBlueprint::estimateTotalKm($blueprint),
            (float) $day->fresh()->target_km,
        );
    }

    public function test_type_swap_to_interval_recomputes(): void
    {
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Easy,
            'target_km' => 8.0,
            'intervals_json' => null,
        ]);

        $blueprint = $this->blueprint();
        $day->update([
            'type' => TrainingType::Interval,
            'intervals_json' => $blueprint,
        ]);

        $this->assertSame(
            IntervalBlueprint::estimateTotalKm($blueprint),
            (float) $day->fresh()->target_km,
        );
    }

    public function test_non_interval_day_keeps_explicit_target_km(): void
    {
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Easy,
            'target_km' => 8.0,
            'intervals_json' => null,
        ]);

        $day->update(['target_km' => 5.0]);

        $this->assertSame(5.0, (float) $day->fresh()->target_km);
    }

    public function test_interval_day_without_blueprint_keeps_target_km(): void
    {
        // Shouldn't exist post-optimizer, but the hook must not null the
        // distance when there's nothing to estimate from.
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Interval,
            'target_km' => 6.0,
            'intervals_json' => null,
        ]);

        $this->assertSame(6.0, (float) $day->fresh()->target_km);
    }

    public function test_date_only_update_is_a_noop_for_target_km(): void
    {
        // Reschedule path (PATCH /training-days/{day}) saves without touching
        // intervals — the recompute must be stable (same blueprint → same km).
        $day = TrainingDay::factory()->create([
            'type' => TrainingType::Interval,
            'intervals_json' => $this->blueprint(),
        ]);
        $km = (float) $day->fresh()->target_km;

        $day->fresh()->update(['date' => now()->addDays(3)->toDateString()]);

        $this->assertSame($km, (float) $day->fresh()->target_km);
    }
}
