<?php

namespace Tests\Feature\Migrations;

use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class RecomputeIntervalTargetKmTest extends TestCase
{
    use LazilyRefreshDatabase;

    private string $migration = 'database/migrations/2026_06_10_120000_recompute_interval_day_target_km.php';

    /**
     * @return array<string,mixed>
     */
    private function blueprint(): array
    {
        return [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];
    }

    private function makeWeek(): TrainingWeek
    {
        $goal = Goal::factory()->create();

        return TrainingWeek::factory()->create(['goal_id' => $goal->id]);
    }

    /**
     * Raw write (bypasses the model saving hook) so we can stage the exact
     * pre-migration stale state.
     */
    private function makeRawDay(TrainingWeek $week, string $type, float $targetKm, ?array $intervals, int $order): TrainingDay
    {
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => 'easy',
            'target_km' => 5.0,
            'intervals_json' => null,
            'order' => $order,
        ]);
        DB::table('training_days')->where('id', $day->id)->update([
            'type' => $type,
            'target_km' => $targetKm,
            'intervals_json' => $intervals === null ? null : json_encode($intervals),
        ]);

        return $day;
    }

    private function runUp(): void
    {
        (include base_path($this->migration))->up();
    }

    public function test_recomputes_stale_interval_rows_and_week_totals(): void
    {
        $week = $this->makeWeek();
        $interval = $this->makeRawDay($week, 'interval', 12.0, $this->blueprint(), 2);
        $easy = $this->makeRawDay($week, 'easy', 8.0, null, 4);
        DB::table('training_weeks')->where('id', $week->id)->update(['total_km' => 20.0]);

        $this->runUp();

        $expected = IntervalBlueprint::estimateTotalKm($this->blueprint());
        $this->assertSame($expected, (float) $interval->fresh()->target_km);
        $this->assertSame(8.0, (float) $easy->fresh()->target_km);
        $this->assertSame(
            round($expected + 8.0, 1),
            (float) $week->fresh()->total_km,
        );
    }

    public function test_leaves_interval_rows_without_blueprint_alone(): void
    {
        $week = $this->makeWeek();
        $day = $this->makeRawDay($week, 'interval', 6.0, null, 2);
        DB::table('training_weeks')->where('id', $week->id)->update(['total_km' => 6.0]);

        $this->runUp();

        $this->assertSame(6.0, (float) $day->fresh()->target_km);
        $this->assertSame(6.0, (float) $week->fresh()->total_km);
    }

    public function test_is_idempotent(): void
    {
        $week = $this->makeWeek();
        $interval = $this->makeRawDay($week, 'interval', 12.0, $this->blueprint(), 2);

        $this->runUp();
        $afterFirst = (float) $interval->fresh()->target_km;
        $weekAfterFirst = (float) $week->fresh()->total_km;

        $this->runUp();

        $this->assertSame($afterFirst, (float) $interval->fresh()->target_km);
        $this->assertSame($weekAfterFirst, (float) $week->fresh()->total_km);
    }
}
