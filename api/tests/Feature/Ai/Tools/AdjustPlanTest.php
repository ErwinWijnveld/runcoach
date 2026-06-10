<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\AdjustPlan;
use App\Enums\GoalStatus;
use App\Enums\PaceConfidence;
use App\Enums\PaceDerivation;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\TrainingType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use App\Support\Intervals\IntervalBlueprint;
use App\Support\Onboarding\FitnessSnapshot;
use App\Support\Onboarding\OnboardingFormInput;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class AdjustPlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function snapshot(): FitnessSnapshot
    {
        return new FitnessSnapshot(
            thresholdPaceSecondsPerKm: 330,
            easyPaceSecondsPerKm: 360,
            vo2maxPaceSecondsPerKm: 310,
            confidence: PaceConfidence::Medium,
            derivation: PaceDerivation::HrZonePace,
            weeklyKmRecent4Weeks: 25.0,
            weeklyRunsRecent4Weeks: 4.0,
            longestRunRecent8Weeks: 12.0,
            maxHeartRate: 190,
            hasIntensityHistory: true,
        );
    }

    private function makeTool(User $user): AdjustPlan
    {
        return new AdjustPlan(
            user: $user,
            optimizer: app(PlanOptimizerService::class),
            proposals: app(ProposalService::class),
        );
    }

    /**
     * Build a draft proposal end-to-end (snapshot → builder → optimizer →
     * persistPending) so the AdjustPlan tool has something
     * realistic to operate on.
     */
    private function seedProposal(User $user, ?string $targetDate = null): CoachProposal
    {
        $form = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'goal_name' => 'Test Race',
            'distance_meters' => 5000,
            'target_date' => $targetDate ?? now()->addWeeks(8)->endOfWeek()->toDateString(),
            'goal_time_seconds' => 1500,
            'days_per_week' => 4,
            'preferred_weekdays' => [1, 2, 4, 6, 7],
            'coach_style' => 'balanced',
        ]);
        $payload = app(TrainingPlanBuilder::class)->build($this->snapshot(), $form);
        $payload = app(PlanOptimizerService::class)->optimize($payload, $user);

        return app(ProposalService::class)->persistPending(
            $user,
            ProposalType::CreateSchedule,
            $payload,
        );
    }

    /**
     * An active goal with a single editable easy day on week 1, Tuesday.
     * target_date is null so the race-day optimizer passes stay no-ops.
     */
    private function seedActiveGoal(User $user): Goal
    {
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
            'target_date' => null,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek(),
            'total_km' => 20,
        ]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'order' => 2,
            'date' => now()->startOfWeek()->addDay(),
            'type' => TrainingType::Easy->value,
            'title' => 'Easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
            'intervals_json' => null,
        ]);

        return $goal->fresh();
    }

    public function test_replace_swaps_session_type(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Pick the first easy day from the plan.
        $week = collect($proposal->payload['schedule']['weeks'])
            ->firstWhere(fn ($w) => collect($w['days'])->contains(fn ($d) => $d['type'] === TrainingType::Easy->value));
        $easyDay = collect($week['days'])->firstWhere('type', TrainingType::Easy->value);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner asked for more interval work.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => $week['week_number'],
                        'day_of_week' => $easyDay['day_of_week'],
                        'type' => TrainingType::Interval->value,
                        'description' => 'Extra interval session per runner request.',
                    ],
                ],
            ]),
        ])), true);

        $this->assertTrue($result['requires_approval']);
        $this->assertCount(1, $result['applied']);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $week['week_number']);
        $editedDay = collect($newWeek['days'])->firstWhere('day_of_week', $easyDay['day_of_week']);
        $this->assertSame(TrainingType::Interval->value, $editedDay['type']);
    }

    public function test_replace_swap_to_interval_regenerates_title_and_synthesizes_intervals(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find a tempo day from the seeded plan and swap it to interval
        // WITHOUT providing an intervals[] array. The bug we're guarding
        // against: title stays "Tempo" + intervals stays missing → the
        // resulting card / details sheet looks identical to the original.
        $week = collect($proposal->payload['schedule']['weeks'])
            ->firstWhere(fn ($w) => collect($w['days'])->contains(fn ($d) => $d['type'] === TrainingType::Tempo->value));
        if ($week === null) {
            $this->markTestSkipped('Seeded plan has no tempo day to swap.');
        }
        $tempoDay = collect($week['days'])->firstWhere('type', TrainingType::Tempo->value);
        $this->assertSame('Tempo', $tempoDay['title']);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner asked to swap tempo for an interval session.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => $week['week_number'],
                        'day_of_week' => $tempoDay['day_of_week'],
                        'type' => TrainingType::Interval->value,
                        'description' => 'Swap tempo for intervals.',
                    ],
                ],
            ]),
        ])), true);

        $this->assertTrue($result['requires_approval']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $week['week_number']);
        $editedDay = collect($newWeek['days'])->firstWhere('day_of_week', $tempoDay['day_of_week']);

        $this->assertSame(TrainingType::Interval->value, $editedDay['type']);
        $this->assertSame('Intervals', $editedDay['title']);
        $this->assertNull($editedDay['target_pace_seconds_per_km']);
        // Canonical grouped blueprint synthesized for a naked interval swap.
        $intervals = $editedDay['intervals'];
        $this->assertIsArray($intervals);
        $this->assertArrayHasKey('steps', $intervals);
        $this->assertNotEmpty($intervals['steps']);
        $this->assertSame('block', $intervals['steps'][0]['type']);
        $this->assertNotNull($intervals['warmup_seconds']);
        $this->assertNotNull($intervals['cooldown_seconds']);
    }

    public function test_remove_drops_session(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);
        $week = $proposal->payload['schedule']['weeks'][0];
        $day = $week['days'][0];

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner has a conflict on Monday week 1.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'remove', 'week' => $week['week_number'], 'day_of_week' => $day['day_of_week']],
                ],
            ]),
        ])), true);

        $this->assertTrue($result['requires_approval']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $week['week_number']);
        if ($newWeek === null) {
            // Empty week was dropped by the optimizer — also valid.
            $this->assertNotEquals($proposal->id, $result['proposal_id']);

            return;
        }
        $remainingDows = array_map(fn ($d) => $d['day_of_week'], $newWeek['days']);
        $this->assertNotContains($day['day_of_week'], $remainingDows);
    }

    public function test_add_session_respects_preferred_weekdays(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find an empty slot in week 1 — pick a preferred weekday not yet used.
        $week = $proposal->payload['schedule']['weeks'][0];
        $usedDows = array_map(fn ($d) => $d['day_of_week'], $week['days']);
        $available = collect($proposal->payload['preferred_weekdays'])
            ->reject(fn ($d) => in_array($d, $usedDows, true))
            ->values();
        if ($available->isEmpty()) {
            $this->markTestSkipped('No spare preferred weekday in week 1 to add to.');
        }
        $newDow = (int) $available->first();

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner mentioned wanting an extra easy day.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'add',
                        'week' => $week['week_number'],
                        'day_of_week' => $newDow,
                        'type' => TrainingType::Easy->value,
                        'target_km' => 5.0,
                        'description' => 'Extra easy day per runner request.',
                    ],
                ],
            ]),
        ])), true);

        $this->assertCount(1, $result['applied']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $week['week_number']);
        $newDay = collect($newWeek['days'])->firstWhere('day_of_week', $newDow);
        $this->assertNotNull($newDay);
        $this->assertSame(TrainingType::Easy->value, $newDay['type']);
    }

    public function test_add_session_outside_preferred_weekdays_is_rejected(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        $forbiddenDow = collect([1, 2, 3, 4, 5, 6, 7])
            ->reject(fn ($d) => in_array($d, $proposal->payload['preferred_weekdays'], true))
            ->first();
        if ($forbiddenDow === null) {
            $this->markTestSkipped('Runner has no forbidden weekdays.');
        }

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Trying to add on a day the runner did not pick.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'add',
                        'week' => 1,
                        'day_of_week' => $forbiddenDow,
                        'type' => TrainingType::Easy->value,
                    ],
                ],
            ]),
        ])), true);

        $this->assertEmpty($result['applied'] ?? []);
        $this->assertNotEmpty($result['rejected']);
        $this->assertStringContainsString('preferred_weekdays', $result['rejected'][0]['reason']);
    }

    public function test_race_day_cannot_be_modified(): void
    {
        $user = User::factory()->create();
        $target = now()->addWeeks(8)->endOfWeek();
        $proposal = $this->seedProposal($user, $target->toDateString());

        $weekStart = now()->startOfWeek();
        $weekIdx = (int) $weekStart->diffInWeeks($target);
        $raceWeek = $proposal->payload['schedule']['weeks'][$weekIdx];

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Trying to remove the race itself.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'remove',
                        'week' => $raceWeek['week_number'],
                        'day_of_week' => (int) $target->isoWeekday(),
                    ],
                ],
            ]),
        ])), true);

        $this->assertEmpty($result['applied'] ?? []);
        $this->assertNotEmpty($result['rejected']);
        $this->assertStringContainsString('race day', $result['rejected'][0]['reason']);
    }

    public function test_pace_override_is_honored_exactly_on_quality_day(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find a tempo day.
        $tempoDay = null;
        $tempoWeek = null;
        foreach ($proposal->payload['schedule']['weeks'] as $w) {
            foreach ($w['days'] as $d) {
                if ($d['type'] === TrainingType::Tempo->value) {
                    $tempoDay = $d;
                    $tempoWeek = $w;
                    break 2;
                }
            }
        }
        if ($tempoDay === null) {
            $this->markTestSkipped('Plan has no tempo day.');
        }
        $original = (int) $tempoDay['target_pace_seconds_per_km'];
        // Ask for 60 sec/km faster — a far bigger jump than the old ±15s
        // window. The runner explicitly requested it, so it must stick verbatim.
        $requested = $original - 60;

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner asked for a much faster tempo pace.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'adjust',
                        'week' => $tempoWeek['week_number'],
                        'day_of_week' => $tempoDay['day_of_week'],
                        'target_pace_seconds_per_km' => $requested,
                    ],
                ],
            ]),
        ])), true);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $tempoWeek['week_number']);
        $newTempo = collect($newWeek['days'])->firstWhere('day_of_week', $tempoDay['day_of_week']);
        $this->assertSame($requested, $newTempo['target_pace_seconds_per_km']);
    }

    public function test_pace_override_is_honored_on_easy_day(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find an easy day. Easy/long-run paces used to be silently ignored
        // (they "tracked the snapshot"); now an explicit request must stick.
        $easyDay = null;
        $easyWeek = null;
        foreach ($proposal->payload['schedule']['weeks'] as $w) {
            foreach ($w['days'] as $d) {
                if ($d['type'] === TrainingType::Easy->value) {
                    $easyDay = $d;
                    $easyWeek = $w;
                    break 2;
                }
            }
        }
        if ($easyDay === null) {
            $this->markTestSkipped('Plan has no easy day.');
        }
        $requested = 300; // 5:00/km — well inside the physiological sanity window

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner asked to set their easy pace explicitly.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'adjust',
                        'week' => $easyWeek['week_number'],
                        'day_of_week' => $easyDay['day_of_week'],
                        'target_pace_seconds_per_km' => $requested,
                    ],
                ],
            ]),
        ])), true);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $easyWeek['week_number']);
        $editedDay = collect($newWeek['days'])->firstWhere('day_of_week', $easyDay['day_of_week']);
        $this->assertSame($requested, $editedDay['target_pace_seconds_per_km']);
    }

    public function test_distance_override_is_honored_below_old_minimum(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find an easy day and ask for a 3km shakeout — below the old 4km
        // floor + the optimizer's min-run-length bump. Must stick verbatim.
        $easyDay = null;
        $easyWeek = null;
        foreach ($proposal->payload['schedule']['weeks'] as $w) {
            foreach ($w['days'] as $d) {
                if ($d['type'] === TrainingType::Easy->value) {
                    $easyDay = $d;
                    $easyWeek = $w;
                    break 2;
                }
            }
        }
        if ($easyDay === null) {
            $this->markTestSkipped('Plan has no easy day.');
        }

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Runner wants a short shakeout.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'adjust',
                        'week' => $easyWeek['week_number'],
                        'day_of_week' => $easyDay['day_of_week'],
                        'target_km' => 3,
                    ],
                ],
            ]),
        ])), true);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $easyWeek['week_number']);
        $edited = collect($newWeek['days'])->firstWhere('day_of_week', $easyDay['day_of_week']);
        $this->assertSame(3.0, (float) $edited['target_km']);
    }

    public function test_diff_carries_before_and_after_snapshots(): void
    {
        $user = User::factory()->create();
        // Active-goal edit so the proposal carries a `diff`.
        $goal = $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Swap the easy day for a tempo.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'replace', 'week' => 1, 'day_of_week' => 2, 'type' => TrainingType::Tempo->value],
                ],
            ]),
        ])), true);

        $this->assertSame(ProposalType::EditActivePlan->value, $result['proposal_type']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $diff = $newProposal->payload['diff'];
        $this->assertNotEmpty($diff);
        $entry = $diff[0];
        // before = the original easy day; after (flat) = the new tempo day.
        $this->assertSame(TrainingType::Easy->value, $entry['before']['type']);
        $this->assertSame(TrainingType::Tempo->value, $entry['type']);
    }

    public function test_diff_notes_out_of_range_hr_zone_was_not_applied(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Set an impossible HR zone.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'adjust', 'week' => 1, 'day_of_week' => 2, 'target_heart_rate_zone' => 9],
                ],
            ]),
        ])), true);

        $applied = $result['applied'][0];
        $this->assertArrayHasKey('adjustments', $applied);
        $this->assertStringContainsString('1–5', implode(' ', $applied['adjustments']));
    }

    public function test_diff_carries_interval_summary_for_interval_day(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Swap the easy day for a specific interval session.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => 1,
                        'day_of_week' => 2,
                        'type' => TrainingType::Interval->value,
                        'intervals' => [
                            'warmup_seconds' => 60,
                            'steps' => [['type' => 'block', 'reps' => 5, 'work_distance_m' => 1000, 'work_pace_seconds_per_km' => 250, 'recovery_seconds' => 90]],
                            'cooldown_seconds' => 300,
                        ],
                    ],
                ],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        // The diff shows the exact stored interval structure, so the agent
        // can describe the session from what landed, not what it sent.
        $this->assertIsString($entry['intervals']);
        $this->assertStringContainsString('5×1000m', $entry['intervals']);
    }

    public function test_interval_day_distance_is_derived_from_blueprint_and_noted(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $blueprint = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 5, 'work_distance_m' => 1000, 'work_pace_seconds_per_km' => 250, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Interval session with an explicit distance the structure contradicts.',
            'operations' => json_encode([
                'operations' => [[
                    'action' => 'replace',
                    'week' => 1,
                    'day_of_week' => 2,
                    'type' => TrainingType::Interval->value,
                    'target_km' => 15.0,
                    'intervals' => $blueprint,
                ]],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        // Stored distance is derived from the session structure, not the
        // agent's claim — and the note tells the agent why.
        $this->assertSame(IntervalBlueprint::estimateTotalKm($blueprint), $entry['target_km']);
        $this->assertStringContainsString('session structure', implode(' ', $entry['adjustments']));
    }

    public function test_invalid_intervals_are_replaced_with_default_and_noted(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Send a broken interval structure.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => 1,
                        'day_of_week' => 2,
                        'type' => TrainingType::Interval->value,
                        'intervals' => ['steps' => ['not-a-step']],
                    ],
                ],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        $this->assertStringContainsString('default interval session', implode(' ', $entry['adjustments']));
        // The diff shows the skeleton that was actually stored.
        $this->assertStringContainsString('4×400m', $entry['intervals']);
    }

    public function test_intervals_on_non_interval_day_are_not_applied_and_noted(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Intervals on an easy day.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'adjust',
                        'week' => 1,
                        'day_of_week' => 2,
                        'intervals' => ['steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'recovery_seconds' => 90]]],
                    ],
                ],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        $this->assertStringContainsString('was not applied', implode(' ', $entry['adjustments']));
        $this->assertArrayNotHasKey('intervals', $entry);
    }

    public function test_interval_clamp_notes_surface_in_adjustments(): void
    {
        $user = User::factory()->create();
        $this->seedActiveGoal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'A hundred reps.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => 1,
                        'day_of_week' => 2,
                        'type' => TrainingType::Interval->value,
                        'intervals' => [
                            'steps' => [['type' => 'block', 'reps' => 100, 'work_distance_m' => 400, 'recovery_seconds' => 90]],
                            'cooldown_seconds' => 300,
                        ],
                    ],
                ],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        $this->assertStringContainsString('you asked for 100', implode(' ', $entry['adjustments']));
        $this->assertStringContainsString('60×400m', $entry['intervals']);
    }

    public function test_shift_entry_carries_interval_summary(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
            'target_date' => null,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek(),
            'total_km' => 20,
        ]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'order' => 4,
            'date' => now()->startOfWeek()->addDays(3),
            'type' => TrainingType::Interval->value,
            'title' => 'Intervals',
            'target_km' => 6.0,
            'target_pace_seconds_per_km' => null,
            'intervals_json' => [
                'warmup_seconds' => 60,
                'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
                'cooldown_seconds' => 300,
            ],
        ]);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Move intervals to Saturday.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'shift', 'week' => 1, 'from_day_of_week' => 4, 'to_day_of_week' => 6],
                ],
            ]),
        ])), true);

        $entry = $result['applied'][0];
        $this->assertStringContainsString('4×800m', $entry['intervals']);
        $this->assertStringContainsString('4×800m', $entry['before']['intervals']);
    }

    public function test_stale_pending_proposal_does_not_hijack_active_plan_edit(): void
    {
        $user = User::factory()->create();
        $goal = $this->seedActiveGoal($user);

        // A leftover pending CreateSchedule from an earlier onboarding
        // attempt, created BEFORE the active goal — must not be the target.
        $stale = $this->seedProposal($user);
        $stale->forceFill(['created_at' => now()->subWeek()])->save();
        $goal->forceFill(['created_at' => now()->subDay()])->save();

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Edit the live plan.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'adjust', 'week' => 1, 'day_of_week' => 2, 'target_km' => 7],
                ],
            ]),
        ])), true);

        $this->assertSame(ProposalType::EditActivePlan->value, $result['proposal_type']);
    }

    public function test_no_pending_proposal_returns_error(): void
    {
        $user = User::factory()->create();
        // No proposal seeded.
        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Should fail.',
            'operations' => json_encode(['operations' => []]),
        ])), true);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_shift_moves_day_to_different_weekday(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Find an existing day; pick a free weekday in the same week.
        $week = $proposal->payload['schedule']['weeks'][0];
        $existingDow = $week['days'][0]['day_of_week'];
        $usedDows = array_map(fn ($d) => $d['day_of_week'], $week['days']);
        $freeDow = collect([1, 2, 3, 4, 5, 6, 7])
            ->reject(fn ($d) => in_array($d, $usedDows, true))
            ->first();
        if ($freeDow === null) {
            $this->markTestSkipped('No free weekday to shift into.');
        }

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Move it to Wednesday.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'shift',
                        'week' => $week['week_number'],
                        'from_day_of_week' => $existingDow,
                        'to_day_of_week' => $freeDow,
                    ],
                ],
            ]),
        ])), true);

        $this->assertCount(1, $result['applied']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $week['week_number']);
        $newDows = array_map(fn ($d) => $d['day_of_week'], $newWeek['days']);
        $this->assertContains($freeDow, $newDows);
        $this->assertNotContains($existingDow, $newDows);
    }

    public function test_shift_into_occupied_slot_is_rejected(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        $week = $proposal->payload['schedule']['weeks'][0];
        if (count($week['days']) < 2) {
            $this->markTestSkipped('Need at least 2 days to test shift collision.');
        }
        $fromDow = $week['days'][0]['day_of_week'];
        $occupiedDow = $week['days'][1]['day_of_week'];

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Trying to shift into a taken slot.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'shift',
                        'week' => $week['week_number'],
                        'from_day_of_week' => $fromDow,
                        'to_day_of_week' => $occupiedDow,
                    ],
                ],
            ]),
        ])), true);

        $this->assertEmpty($result['applied'] ?? []);
        $this->assertNotEmpty($result['rejected']);
    }

    public function test_set_goal_updates_metadata(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        $newDate = now()->addWeeks(12)->endOfWeek()->toDateString();
        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Race got moved.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'set_goal',
                        'goal_name' => 'Updated Race',
                        'goal_time_seconds' => 1800,
                        'target_date' => $newDate,
                    ],
                ],
            ]),
        ])), true);

        $this->assertCount(1, $result['applied']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $this->assertSame('Updated Race', $newProposal->payload['goal_name']);
        $this->assertSame(1800, $newProposal->payload['goal_time_seconds']);
        $this->assertSame($newDate, $newProposal->payload['target_date']);
    }

    public function test_set_goal_rejects_invalid_distance(): void
    {
        $user = User::factory()->create();
        $this->seedProposal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Invalid distance.',
            'operations' => json_encode([
                'operations' => [
                    ['action' => 'set_goal', 'distance' => '7k'],
                ],
            ]),
        ])), true);

        $this->assertEmpty($result['applied'] ?? []);
        $this->assertNotEmpty($result['rejected']);
    }

    public function test_targets_active_goal_when_no_pending_proposal(): void
    {
        // When no pending proposal exists but the runner has an active
        // Goal, AdjustPlan should target the goal in-place and emit an
        // EditActivePlan proposal with `diff` attached for the UI.
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        // Apply the proposal so the goal becomes active and the proposal
        // is marked Accepted (no longer pending).
        app(ProposalService::class)->apply($proposal, $user);

        $goal = $user->goals()->where('status', GoalStatus::Active)->first();
        $this->assertNotNull($goal, 'goal should be active after apply');

        // Find the first non-race training day on the active plan.
        $firstWeek = $goal->trainingWeeks()->orderBy('week_number')->first();
        $firstDay = $firstWeek->trainingDays()->orderBy('order')->first();

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Make it a tempo.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => $firstWeek->week_number,
                        'day_of_week' => $firstDay->order,
                        'type' => TrainingType::Tempo->value,
                    ],
                ],
            ]),
        ])), true);

        $this->assertSame(ProposalType::EditActivePlan->value, $result['proposal_type']);
        $newProposal = CoachProposal::find($result['proposal_id']);
        $this->assertArrayHasKey('diff', $newProposal->payload, 'active-goal edits must carry a diff for the revision UI');
        $this->assertNotEmpty($newProposal->payload['diff']);
    }

    public function test_pending_proposal_edit_does_not_carry_diff(): void
    {
        // Onboarding-style edits (still-pending CreateSchedule proposal)
        // must NOT include a diff — the runner hasn't seen any prior
        // version of the plan, so a "PLAN REVISION" card would confuse.
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);
        $week = $proposal->payload['schedule']['weeks'][0];

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Tweak.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'replace',
                        'week' => $week['week_number'],
                        'day_of_week' => $week['days'][0]['day_of_week'],
                        'type' => TrainingType::Easy->value,
                    ],
                ],
            ]),
        ])), true);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $this->assertSame(ProposalType::CreateSchedule->value, $result['proposal_type']);
        $this->assertArrayNotHasKey('diff', $newProposal->payload);
    }

    public function test_no_ops_means_no_new_proposal(): void
    {
        $user = User::factory()->create();
        $proposal = $this->seedProposal($user);

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Empty op list.',
            'operations' => json_encode(['operations' => []]),
        ])), true);

        $this->assertFalse($result['requires_approval']);
        // Original proposal still pending.
        $proposal->refresh();
        $this->assertSame(ProposalStatus::Pending, $proposal->status);
    }
}
