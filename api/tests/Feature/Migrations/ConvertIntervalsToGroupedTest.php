<?php

namespace Tests\Feature\Migrations;

use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class ConvertIntervalsToGroupedTest extends TestCase
{
    use LazilyRefreshDatabase;

    private string $migration = 'database/migrations/2026_06_09_183949_convert_intervals_json_to_grouped_blueprint.php';

    private function makeDay(mixed $intervalsJson): TrainingDay
    {
        $goal = Goal::factory()->create();
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id, 'type' => 'interval']);
        // Write the raw JSON directly so the model cast doesn't reshape it.
        DB::table('training_days')->where('id', $day->id)->update([
            'intervals_json' => $intervalsJson === null ? null : json_encode($intervalsJson),
        ]);

        return $day;
    }

    private function runUp(): void
    {
        (include base_path($this->migration))->up();
    }

    public function test_folds_legacy_flat_rows_into_grouped(): void
    {
        $day = $this->makeDay([
            ['kind' => 'warmup', 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
            ['kind' => 'work', 'distance_m' => 800, 'target_pace_seconds_per_km' => 270],
            ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
            ['kind' => 'work', 'distance_m' => 800, 'target_pace_seconds_per_km' => 270],
            ['kind' => 'recovery', 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
            ['kind' => 'cooldown', 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
        ]);

        $this->runUp();

        $grouped = $day->fresh()->intervals_json;
        $this->assertArrayHasKey('steps', $grouped);
        $this->assertSame(60, $grouped['warmup_seconds']);
        $this->assertSame(300, $grouped['cooldown_seconds']);
        $this->assertCount(1, $grouped['steps']);
        $this->assertSame(2, $grouped['steps'][0]['reps']);
        $this->assertSame(800, $grouped['steps'][0]['work_distance_m']);
    }

    public function test_is_idempotent_for_already_grouped_rows(): void
    {
        $grouped = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 260, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];
        $day = $this->makeDay($grouped);

        $this->runUp();

        $this->assertSame($grouped, $day->fresh()->intervals_json);
    }

    public function test_nulls_unfoldable_garbage(): void
    {
        $day = $this->makeDay(['totally' => 'wrong']);

        $this->runUp();

        $this->assertNull($day->fresh()->intervals_json);
    }

    public function test_nulling_unfoldable_garbage_logs_a_warning(): void
    {
        Log::spy();
        $day = $this->makeDay(['totally' => 'wrong']);

        $this->runUp();

        $this->assertNull($day->fresh()->intervals_json);
        Log::shouldHaveReceived('warning')->once()->withArgs(
            fn ($message, $context = []) => ($context['training_day_id'] ?? null) === $day->id,
        );
    }
}
