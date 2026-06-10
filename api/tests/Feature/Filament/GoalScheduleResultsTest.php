<?php

namespace Tests\Feature\Filament;

use App\Enums\TrainingType;
use App\Filament\Coach\Pages\GoalSchedule;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use Filament\Schemas\Components\View;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class GoalScheduleResultsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_completed_day_shows_ring_and_actuals_line(): void
    {
        [$user, $goal, , $day] = $this->planWithDay();
        $this->resultFor($day, [
            'compliance_score' => 8.7,
            'actual_km' => 8.2,
            'actual_pace_seconds_per_km' => 286,
            'actual_avg_heart_rate' => 162.0,
        ]);
        $this->actingAs($user);

        Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Completed')
            ->assertSee('Ran 8.2 km @ 4:46/km · avg HR 162')
            ->assertSeeHtml('gs-day-ring')
            ->assertSeeHtml('rc-ring-grade');
    }

    public function test_actuals_line_omits_heart_rate_when_absent(): void
    {
        [$user, $goal, , $day] = $this->planWithDay();
        $this->resultFor($day, [
            'actual_km' => 5.0,
            'actual_pace_seconds_per_km' => 330,
            'actual_avg_heart_rate' => null,
        ]);
        $this->actingAs($user);

        Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Ran 5 km @ 5:30/km')
            ->assertDontSee('avg HR');
    }

    public function test_day_rings_are_color_banded_by_score(): void
    {
        [$user, $goal, $week, $day] = $this->planWithDay();
        $this->resultFor($day, ['compliance_score' => 8.7]);

        $okDay = TrainingDay::factory()->create(['training_week_id' => $week->id, 'order' => 2]);
        $this->resultFor($okDay, ['compliance_score' => 6.0]);

        $badDay = TrainingDay::factory()->create(['training_week_id' => $week->id, 'order' => 3]);
        $this->resultFor($badDay, ['compliance_score' => 3.0]);

        $this->actingAs($user);

        // `stroke="#..."` only exists in rendered ring SVGs — the bare hex
        // values also sit in the page CSS, so they can't discriminate.
        Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSeeHtml('stroke="#34C759"')
            ->assertSeeHtml('stroke="#E9B638"')
            ->assertSeeHtml('stroke="#8F3A3A"');
    }

    public function test_week_header_shows_rollup_only_for_weeks_with_results(): void
    {
        [$user, $goal, $week, $day] = $this->planWithDay();
        TrainingDay::factory()->create(['training_week_id' => $week->id, 'order' => 2]);
        $this->resultFor($day, ['compliance_score' => 8.7]);

        TrainingWeek::factory()->create(['goal_id' => $goal->id, 'week_number' => 2]);

        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('1/2 done · avg 8.7');

        $page = $component->instance();
        $freshGoal = $page->goal;
        $weeks = $freshGoal->trainingWeeks->sortBy('week_number')->values();

        $this->assertSame(
            ['done' => 1, 'total' => 2, 'avg' => 8.7],
            $page->weekResultStats($weeks[0]),
        );
        $this->assertNull($page->weekResultStats($weeks[1]));
    }

    public function test_hero_shows_sessions_done_and_plan_compliance(): void
    {
        [$user, $goal, $week, $day] = $this->planWithDay();
        TrainingDay::factory()->create(['training_week_id' => $week->id, 'order' => 2]);
        $this->resultFor($day, ['compliance_score' => 8.0]);

        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Compliance')
            ->assertSee('1 / 2 done');

        $stats = $component->instance()->planResultStats($component->instance()->goal);
        $this->assertSame(['done' => 1, 'total' => 2, 'avg' => 8.0], $stats);
    }

    public function test_hero_compliance_is_dash_when_no_results(): void
    {
        [$user, $goal] = $this->planWithDay();
        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Compliance');

        $stats = $component->instance()->planResultStats($component->instance()->goal);
        $this->assertSame(['done' => 0, 'total' => 1, 'avg' => null], $stats);
    }

    public function test_result_panel_builds_app_style_comparison_rows(): void
    {
        [$user, $goal, , $day] = $this->planWithDay([
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 290,
            'target_heart_rate_zone' => 3,
        ]);
        $activity = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'duration_seconds' => 2352,
            'max_heartrate' => 174.0,
            'elevation_gain_meters' => 124,
            'calories_kcal' => 512,
        ]);
        $this->resultFor($day, [
            'wearable_activity_id' => $activity->id,
            'compliance_score' => 8.7,
            'pace_score' => 9.1,
            'distance_score' => 9.7,
            'heart_rate_score' => 7.4,
            'actual_km' => 8.2,
            'actual_pace_seconds_per_km' => 286,
            'actual_avg_heart_rate' => 162.0,
            'ai_feedback' => 'Strong tempo effort, well executed.',
        ]);
        $this->actingAs($user);

        $panel = $this->resultPanel($goal, $day);

        $this->assertSame('8.7', $panel['grade']);
        $this->assertSame('good', $panel['band']);
        $this->assertSame([
            ['label' => 'Distance', 'target' => '8 km', 'actual' => '8.2 km', 'band' => 'good'],
            ['label' => 'Pace', 'target' => '4:50/km', 'actual' => '4:46/km', 'band' => 'good'],
            ['label' => 'Heart rate', 'target' => 'Zone 3', 'actual' => '162 bpm', 'band' => 'ok'],
        ], $panel['rows']);
        $this->assertSame([
            ['label' => 'Distance', 'grade' => '9.7', 'band' => 'good'],
            ['label' => 'Pace', 'grade' => '9.1', 'band' => 'good'],
            ['label' => 'HR', 'grade' => '7.4', 'band' => 'ok'],
        ], $panel['bars']);
        $this->assertSame('39:12 · max HR 174 · 124 m elev · 512 kcal', $panel['activity']);
        $this->assertStringContainsString('Strong tempo effort, well executed.', (string) $panel['feedback']);
    }

    public function test_result_panel_skips_pace_row_on_interval_days(): void
    {
        [$user, $goal, , $day] = $this->planWithDay([
            'type' => TrainingType::Interval,
            'target_km' => 6.0,
            'target_pace_seconds_per_km' => null,
            'target_heart_rate_zone' => null,
        ]);
        $this->resultFor($day, [
            'pace_score' => null,
            'distance_score' => 9.7,
            'heart_rate_score' => null,
            'actual_km' => 6.1,
            'actual_avg_heart_rate' => 168.0,
        ]);
        $this->actingAs($user);

        $panel = $this->resultPanel($goal, $day);

        $labels = array_column($panel['rows'], 'label');
        $this->assertSame(['Distance', 'Heart rate'], $labels);
        // HR row: no target zone → dash target, actual still shown, no band
        // because heart_rate_score is null.
        $this->assertSame(['label' => 'Heart rate', 'target' => '—', 'actual' => '168 bpm', 'band' => null], $panel['rows'][1]);
        $this->assertSame(['Distance'], array_column($panel['bars'], 'label'));
    }

    public function test_result_panel_is_null_for_day_without_result(): void
    {
        [$user, $goal, , $day] = $this->planWithDay();
        $this->actingAs($user);

        $this->assertNull($this->resultPanel($goal, $day));
    }

    public function test_result_panel_skips_activity_extras_when_activity_is_gone(): void
    {
        [$user, $goal, , $day] = $this->planWithDay();
        $result = $this->resultFor($day, ['compliance_score' => 8.7]);
        $result->wearableActivity->delete();

        $this->actingAs($user);

        $panel = $this->resultPanel($goal, $day);

        $this->assertSame('8.7', $panel['grade']);
        $this->assertNull($panel['activity']);
    }

    public function test_modal_schema_includes_result_panel_view_only_for_completed_days(): void
    {
        [$user, $goal, $week, $day] = $this->planWithDay();
        $this->resultFor($day);
        $plainDay = TrainingDay::factory()->create(['training_week_id' => $week->id, 'order' => 2]);
        $this->actingAs($user);

        $this->assertTrue($this->mountedModalHasResultView($goal, $day));
        $this->assertFalse($this->mountedModalHasResultView($goal, $plainDay));
    }

    public function test_hero_renders_big_compliance_ring_with_band_color(): void
    {
        [$user, $goal, , $day] = $this->planWithDay();
        $this->resultFor($day, ['compliance_score' => 8.7]);
        $this->actingAs($user);

        // `stroke-dasharray` only exists in rendered ring SVG markup — the
        // `.rc-ring` class name itself also appears in the page CSS, so it
        // can't discriminate rendered-vs-absent.
        Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSeeHtml('stroke-dasharray')
            ->assertSeeHtml('stroke="#34C759"');
    }

    public function test_hero_ring_is_absent_without_results(): void
    {
        [$user, $goal] = $this->planWithDay();
        $this->actingAs($user);

        Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Compliance')
            ->assertDontSeeHtml('stroke-dasharray');
    }

    public function test_off_plan_runs_show_in_their_week(): void
    {
        [$user, $goal, $week] = $this->planWithDay([
            'date' => '2026-06-02',
        ], ['starts_at' => '2026-06-01']);

        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'distance_meters' => 8200,
            'average_pace_seconds_per_km' => 286,
            'start_date' => '2026-06-04 08:00:00',
        ]);

        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertSee('Off-plan')
            ->assertSee('Run outside schedule')
            ->assertSee('8.2 km · 4:46/km');

        $byWeek = $component->instance()->offPlanRunsByWeek($component->instance()->goal);
        $this->assertCount(1, $byWeek[$week->id]);
    }

    public function test_off_plan_excludes_linked_runs_out_of_range_runs_and_non_runs(): void
    {
        [$user, $goal, $week, $day] = $this->planWithDay([
            'date' => '2026-06-02',
        ], ['starts_at' => '2026-06-01']);

        // Linked to a planned session → not off-plan.
        $linked = WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => '2026-06-02 08:00:00',
        ]);
        $this->resultFor($day, ['wearable_activity_id' => $linked->id]);

        // Outside every week range → not shown.
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Run',
            'start_date' => '2026-07-20 08:00:00',
        ]);

        // Not a run → not shown.
        WearableActivity::factory()->create([
            'user_id' => $user->id,
            'type' => 'Ride',
            'start_date' => '2026-06-04 08:00:00',
        ]);

        $this->actingAs($user);

        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->assertDontSee('Off-plan');

        $byWeek = $component->instance()->offPlanRunsByWeek($component->instance()->goal);
        $this->assertSame([], $byWeek);
    }

    /**
     * @return array<string, mixed>|null
     */
    private function resultPanel(Goal $goal, TrainingDay $day): ?array
    {
        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal]);

        return $component->instance()->resultPanelData(
            TrainingDay::with('result.wearableActivity')->find($day->id),
        );
    }

    /**
     * The modal HTML itself isn't part of the Livewire test render (Filament
     * ships it via wire:partial effects), so we inspect the mounted action's
     * schema for the result-panel View component instead — same style as
     * GoalScheduleIntervalsTest inspecting mounted-action data.
     */
    private function mountedModalHasResultView(Goal $goal, TrainingDay $day): bool
    {
        $component = Livewire::test(GoalSchedule::class, ['goal' => $goal])
            ->mountAction('editDay', ['dayId' => $day->id]);

        $page = $component->instance();
        $schema = $page->getSchema($page->getMountedActionSchemaName());

        foreach ($schema->getFlatComponents(withHidden: true) as $schemaComponent) {
            if ($schemaComponent instanceof View
                && $schemaComponent->getView() === 'filament.coach.components.day-result-panel') {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  array<string, mixed>  $dayAttributes
     * @param  array<string, mixed>  $weekAttributes
     * @return array{0: User, 1: Goal, 2: TrainingWeek, 3: TrainingDay}
     */
    private function planWithDay(array $dayAttributes = [], array $weekAttributes = []): array
    {
        $user = User::factory()->create(['is_superadmin' => true]);
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(array_merge([
            'goal_id' => $goal->id,
            'week_number' => 1,
        ], $weekAttributes));
        $day = TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'type' => TrainingType::Easy,
            'order' => 1,
        ], $dayAttributes));

        return [$user, $goal, $week, $day];
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function resultFor(TrainingDay $day, array $attributes = []): TrainingResult
    {
        // Only create the default activity when the caller didn't supply one —
        // an eager default would leave a stray run with a factory-random
        // start_date that sometimes lands inside the plan's week range and
        // surfaces as a phantom off-plan run (flaky assertDontSee).
        $attributes['wearable_activity_id'] ??= WearableActivity::factory()->create([
            'user_id' => $day->trainingWeek->goal->user_id,
        ])->id;

        return TrainingResult::factory()->create(array_merge([
            'training_day_id' => $day->id,
            'compliance_score' => 8.7,
            'actual_km' => 8.2,
            'actual_pace_seconds_per_km' => 286,
            'actual_avg_heart_rate' => 162.0,
            'pace_score' => 9.1,
            'distance_score' => 9.7,
            'heart_rate_score' => 7.4,
            'ai_feedback' => null,
        ], $attributes));
    }
}
