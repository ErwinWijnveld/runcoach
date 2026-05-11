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
use App\Models\User;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
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

    public function test_pace_override_clamped_to_tolerance_window(): void
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
            $this->markTestSkipped('Plan has no tempo day to clamp.');
        }
        $original = (int) $tempoDay['target_pace_seconds_per_km'];
        $absurd = $original - 60; // ask for 60 sec/km faster — should clamp to -15

        $result = json_decode($this->makeTool($user)->handle(new Request([
            'reason' => 'Test pace clamp.',
            'operations' => json_encode([
                'operations' => [
                    [
                        'action' => 'adjust',
                        'week' => $tempoWeek['week_number'],
                        'day_of_week' => $tempoDay['day_of_week'],
                        'target_pace_seconds_per_km' => $absurd,
                    ],
                ],
            ]),
        ])), true);

        $newProposal = CoachProposal::find($result['proposal_id']);
        $newWeek = collect($newProposal->payload['schedule']['weeks'])
            ->firstWhere('week_number', $tempoWeek['week_number']);
        $newTempo = collect($newWeek['days'])->firstWhere('day_of_week', $tempoDay['day_of_week']);
        // Allowed minimum is original − 15.
        $this->assertSame($original - 15, $newTempo['target_pace_seconds_per_km']);
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
