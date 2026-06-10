<?php

namespace Tests\Feature\Filament;

use App\Enums\TrainingType;
use App\Filament\Coach\Pages\GoalSchedule;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class GoalScheduleIntervalsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_uniform_intervals_parse_into_a_single_block_step(): void
    {
        [$user, $day] = $this->intervalDay($this->uniformSegments(reps: 6));
        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id]);

        $state = $component->instance()->mountedActions[0]['data'] ?? [];

        $this->assertTrue($state['has_warmup']);
        // Filament's numeric inputs surface scalar values that may come back
        // as int OR float depending on the field config — use loose equality.
        $this->assertEquals(60, $state['warmup_seconds']);
        $this->assertEquals(300, $state['cooldown_seconds']);

        // Filament Repeater stores rows with random UUID keys — re-index
        // before subscripting.
        $steps = array_values($state['steps']);
        $this->assertCount(1, $steps);
        $this->assertSame('block', $steps[0]['step_type']);
        $this->assertEquals(6, $steps[0]['reps']);
        $this->assertEquals(400, $steps[0]['work_distance_m']);
        $this->assertEquals(90, $steps[0]['recovery_seconds']);
    }

    public function test_round_trip_save_without_changes_preserves_canonical_shape(): void
    {
        [$user, $day] = $this->intervalDay($this->uniformSegments(reps: 6));
        $this->actingAs($user);

        Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id])
            ->callMountedAction();

        $grouped = $day->fresh()->intervals_json;

        // Canonical grouped: warmup + one 6-rep block + cooldown.
        $this->assertSame(60, $grouped['warmup_seconds']);
        $this->assertSame(300, $grouped['cooldown_seconds']);
        $this->assertCount(1, $grouped['steps']);
        $this->assertSame('block', $grouped['steps'][0]['type']);
        $this->assertSame(6, $grouped['steps'][0]['reps']);
        $this->assertSame(400, $grouped['steps'][0]['work_distance_m']);
        $this->assertSame(90, $grouped['steps'][0]['recovery_seconds']);
    }

    public function test_pyramid_intervals_keep_distinct_blocks_per_unique_pair(): void
    {
        // 400 / 800 / 400 — three blocks, each with 1 rep, since the
        // recovery between is uniform but the work isn't.
        $segments = [
            ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => null, 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
            ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
            ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
            ['kind' => 'work', 'label' => '800m', 'distance_m' => 800, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 280],
            ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
            ['kind' => 'work', 'label' => '400m', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270],
            ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null],
            ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => null, 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null],
        ];

        [$user, $day] = $this->intervalDay($segments);
        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id]);

        $state = $component->instance()->mountedActions[0]['data'] ?? [];
        $steps = array_values($state['steps']);

        $this->assertCount(3, $steps);
        $this->assertSame('block', $steps[0]['step_type']);
        $this->assertEquals(400, $steps[0]['work_distance_m']);
        $this->assertEquals(800, $steps[1]['work_distance_m']);
        $this->assertEquals(400, $steps[2]['work_distance_m']);
    }

    public function test_changing_type_away_from_interval_clears_intervals_json(): void
    {
        [$user, $day] = $this->intervalDay($this->uniformSegments(reps: 4));
        $this->actingAs($user);

        Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id])
            ->setActionData(['type' => TrainingType::Easy->value])
            ->callMountedAction();

        $this->assertNull($day->fresh()->intervals_json);
    }

    public function test_interval_day_cannot_be_saved_without_steps(): void
    {
        // A stepless interval session is meaningless AND would null the
        // derived target_km — block it at the form layer.
        [$user, $day] = $this->intervalDay($this->uniformSegments(reps: 4));
        $this->actingAs($user);
        $originalIntervals = $day->fresh()->intervals_json;

        Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id])
            ->setActionData(['steps' => []])
            ->callMountedAction()
            ->assertHasActionErrors();

        $this->assertSame($originalIntervals, $day->fresh()->intervals_json);
    }

    public function test_saving_interval_day_stores_derived_distance(): void
    {
        [$user, $day] = $this->intervalDay($this->uniformSegments(reps: 6));
        $this->actingAs($user);

        // Coach-typed distance must lose: target_km on interval days is
        // derived from the session structure by the TrainingDay saving hook.
        Livewire::test(GoalSchedule::class, ['goal' => $day->trainingWeek->goal])
            ->mountAction('editDay', ['dayId' => $day->id])
            ->setActionData(['target_km' => 99])
            ->callMountedAction();

        $fresh = $day->fresh();
        $this->assertSame(
            IntervalBlueprint::estimateTotalKm($fresh->intervals_json),
            (float) $fresh->target_km,
        );
    }

    /**
     * @return array{0: User, 1: TrainingDay}
     */
    private function intervalDay(array $segments): array
    {
        $user = User::factory()->create(['is_superadmin' => true]);
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'type' => TrainingType::Interval,
            'target_pace_seconds_per_km' => null,
            'intervals_json' => $segments,
        ]);

        return [$user, $day];
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function uniformSegments(int $reps): array
    {
        $out = [
            ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => null, 'duration_seconds' => 60, 'target_pace_seconds_per_km' => null],
        ];
        for ($i = 0; $i < $reps; $i++) {
            $out[] = ['kind' => 'work', 'label' => '400m rep', 'distance_m' => 400, 'duration_seconds' => null, 'target_pace_seconds_per_km' => 270];
            $out[] = ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => null, 'duration_seconds' => 90, 'target_pace_seconds_per_km' => null];
        }
        $out[] = ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => null, 'duration_seconds' => 300, 'target_pace_seconds_per_km' => null];

        return $out;
    }
}
