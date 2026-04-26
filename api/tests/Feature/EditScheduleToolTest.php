<?php

namespace Tests\Feature;

use App\Ai\Tools\EditSchedule;
use App\Enums\GoalStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class EditScheduleToolTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * @return array<string, mixed>
     */
    private function samplePayload(): array
    {
        return [
            'goal_type' => 'race',
            'goal_name' => 'Amsterdam Half',
            'distance' => '21097',
            'goal_time_seconds' => 6300,
            'target_date' => '2026-09-15',
            'preferred_weekdays' => null,
            'additional_notes' => null,
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'Base',
                        'total_km' => 20,
                        'days' => [
                            ['day_of_week' => 2, 'type' => 'easy', 'title' => 'Easy', 'target_km' => 5.0, 'target_pace_seconds_per_km' => 390, 'target_heart_rate_zone' => 2],
                            ['day_of_week' => 4, 'type' => 'tempo', 'title' => 'Tempo', 'target_km' => 6.0, 'target_pace_seconds_per_km' => 340, 'target_heart_rate_zone' => 3],
                            ['day_of_week' => 6, 'type' => 'long_run', 'title' => 'Long Run', 'target_km' => 10.0, 'target_pace_seconds_per_km' => 420, 'target_heart_rate_zone' => 2],
                        ],
                    ],
                    [
                        'week_number' => 2,
                        'focus' => 'Build',
                        'total_km' => 23,
                        'days' => [
                            ['day_of_week' => 2, 'type' => 'easy', 'title' => 'Easy', 'target_km' => 6.0, 'target_pace_seconds_per_km' => 390, 'target_heart_rate_zone' => 2],
                            ['day_of_week' => 4, 'type' => 'tempo', 'title' => 'Tempo', 'target_km' => 7.0, 'target_pace_seconds_per_km' => 340, 'target_heart_rate_zone' => 3],
                            ['day_of_week' => 6, 'type' => 'long_run', 'title' => 'Long Run', 'target_km' => 12.0, 'target_pace_seconds_per_km' => 420, 'target_heart_rate_zone' => 2],
                        ],
                    ],
                ],
            ],
        ];
    }

    /**
     * @param  array<string, mixed>  $input
     * @return array<string, mixed>
     */
    private function invoke(User $user, array $input): array
    {
        $tool = app(EditSchedule::class, ['user' => $user]);
        $result = json_decode($tool->handle(new Request($input)), true);

        // The tool response intentionally omits the full plan payload to
        // keep the agent's conversation history small (see comment in
        // EditSchedule::handle). Tests want to assert shape though — the
        // persisted proposal is authoritative, so splice its payload in.
        if (is_array($result) && isset($result['proposal_id'])) {
            $proposal = CoachProposal::find($result['proposal_id']);
            if ($proposal) {
                $result['payload'] = $proposal->payload;
            }
        }

        return $result;
    }

    public function test_set_day_updates_fields_and_recalculates_week_total(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 8.0]],
            ]),
        ]);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame('create_schedule', $result['proposal_type']);
        $this->assertEquals(8.0, $result['payload']['schedule']['weeks'][0]['days'][2]['target_km']);
        $this->assertEquals(19.0, $result['payload']['schedule']['weeks'][0]['total_km']);
    }

    public function test_remove_day_drops_entry(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'remove_day', 'week' => 1, 'day_of_week' => 4],
            ]),
        ]);

        $this->assertCount(2, $result['payload']['schedule']['weeks'][0]['days']);
        $this->assertEquals(15.0, $result['payload']['schedule']['weeks'][0]['total_km']);
    }

    public function test_add_day_rejects_when_day_already_taken(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['type' => 'easy', 'title' => 'Duplicate']],
            ]),
        ]);

        $this->assertStringContainsString('already has a day', $result['error']);
    }

    public function test_add_day_appends_new_day(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'title' => 'Easy Shakeout', 'target_km' => 3.0]],
            ]),
        ]);

        // Added day's 3km is bumped to 4km by enforceMinimumRunLength
        // (default baseline = 4km), so total is 5 + 6 + 10 + 4 = 25.
        $this->assertCount(4, $result['payload']['schedule']['weeks'][0]['days']);
        $this->assertEquals(25.0, $result['payload']['schedule']['weeks'][0]['total_km']);
    }

    public function test_add_day_auto_titles_when_title_omitted(): void
    {
        // The agent often forgets to pass `title` on add_day. The
        // optimizer's generateTitles already fills a default from the
        // type label ("Easy", "Long run", etc.), so requiring title up
        // front just causes an extra ~23s round trip while the agent
        // retries. Title is now optional; if omitted it gets
        // auto-generated.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'target_km' => 3.0]],
            ]),
        ]);

        $newDay = collect($result['payload']['schedule']['weeks'][0]['days'])
            ->firstWhere('day_of_week', 7);
        $this->assertNotNull($newDay);
        $this->assertSame('easy', $newDay['type']);
        $this->assertSame('Easy', $newDay['title']);
    }

    public function test_shift_day_moves_to_new_weekday(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'shift_day', 'week' => 2, 'from_day_of_week' => 4, 'to_day_of_week' => 5],
            ]),
        ]);

        $days = collect($result['payload']['schedule']['weeks'][1]['days'])->keyBy('day_of_week');
        $this->assertArrayHasKey(5, $days);
        $this->assertArrayNotHasKey(4, $days);
    }

    public function test_shift_day_rejects_when_target_occupied(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'shift_day', 'week' => 1, 'from_day_of_week' => 2, 'to_day_of_week' => 4],
            ]),
        ]);

        $this->assertStringContainsString('already has a day', $result['error']);
    }

    public function test_set_goal_updates_metadata(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_goal', 'fields' => ['target_date' => '2026-10-10', 'goal_time_seconds' => 5700, 'preferred_weekdays' => [1, 3, 5]]],
            ]),
        ]);

        $this->assertSame('2026-10-10', $result['payload']['target_date']);
        $this->assertSame(5700, $result['payload']['goal_time_seconds']);
        $this->assertSame([1, 3, 5], $result['payload']['preferred_weekdays']);
    }

    public function test_null_proposal_id_targets_latest(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => ['schedule' => ['weeks' => [['week_number' => 1, 'focus' => 'old', 'total_km' => 0, 'days' => []]]]],
        ]);
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 9.0]],
            ]),
        ]);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame('Amsterdam Half', $result['payload']['goal_name']);
    }

    public function test_pending_source_is_superseded_when_edit_tool_creates_new_proposal(): void
    {
        // The edit tool now persists its output as a new pending proposal
        // immediately (so mid-loop verify_plan / edit_schedule auto-target
        // sees the fresh version, not a stale one). The source proposal
        // is therefore Rejected as soon as the tool commits.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertSame(ProposalStatus::Rejected, $proposal->fresh()->status);
        $this->assertNotNull($result['proposal_id']);
        $this->assertNotSame($proposal->id, $result['proposal_id']);

        $this->assertDatabaseHas('coach_proposals', [
            'id' => $result['proposal_id'],
            'user_id' => $user->id,
            'status' => ProposalStatus::Pending->value,
        ]);
    }

    public function test_other_users_proposals_are_not_accessible(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $other->id,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_invalid_operations_payload_returns_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => 'not-json',
        ]);

        $this->assertStringContainsString('non-empty JSON', $result['error']);
    }

    public function test_unknown_op_returns_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([['op' => 'scramble_week']]),
        ]);

        $this->assertStringContainsString('unknown op', $result['error']);
    }

    public function test_day_of_week_out_of_range_returns_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 9, 'fields' => ['target_km' => 5]],
            ]),
        ]);

        $this->assertStringContainsString('day_of_week', $result['error']);
    }

    public function test_no_proposals_returns_error(): void
    {
        $user = User::factory()->create();

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 1, 'fields' => ['target_km' => 5]],
            ]),
        ]);

        $this->assertStringContainsString('No proposal or active plan found', $result['error']);
    }

    public function test_accepted_proposals_cannot_be_edited(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Accepted,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertStringContainsString('already accepted', $result['error']);
    }

    public function test_non_create_schedule_proposals_are_rejected(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::ModifySchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['goal_id' => 1, 'changes' => []],
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertStringContainsString('only edits create_schedule', $result['error']);
    }

    public function test_malformed_schedule_payload_returns_error(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => ['goal_type' => 'race'],
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 5]],
            ]),
        ]);

        $this->assertStringContainsString('schedule.weeks', $result['error']);
    }

    public function test_missing_required_fields_returns_structured_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2],
            ]),
        ]);

        $this->assertStringContainsString("'fields'", $result['error']);
    }

    public function test_error_in_later_op_does_not_supersede_pending_source(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 6.5]],
                ['op' => 'set_day', 'week' => 99, 'day_of_week' => 2, 'fields' => ['target_km' => 5]],
            ]),
        ]);

        $this->assertArrayHasKey('error', $result);
        $this->assertSame(ProposalStatus::Pending, $proposal->fresh()->status);
    }

    public function test_unknown_day_field_is_rejected(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['intensity' => 'high']],
            ]),
        ]);

        $this->assertStringContainsString("unknown day field 'intensity'", $result['error']);
    }

    public function test_invalid_training_type_is_rejected(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['type' => 'hyrox']],
            ]),
        ]);

        $this->assertStringContainsString('type must be one of', $result['error']);
    }

    public function test_negative_target_km_is_rejected(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => -5]],
            ]),
        ]);

        $this->assertStringContainsString('target_km', $result['error']);
    }

    public function test_out_of_range_hr_zone_is_rejected(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_heart_rate_zone' => 9]],
            ]),
        ]);

        $this->assertStringContainsString('target_heart_rate_zone', $result['error']);
    }

    public function test_set_goal_rejects_goal_type_and_coach_style(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_goal', 'fields' => ['goal_type' => 'race']],
            ]),
        ]);

        $this->assertStringContainsString("set_goal does not support field 'goal_type'", $result['error']);
    }

    public function test_set_goal_rejects_invalid_distance(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'set_goal', 'fields' => ['distance' => '21097']],
            ]),
        ]);

        $this->assertStringContainsString('distance must be one of', $result['error']);
    }

    public function test_day_of_week_boundary_values_accepted(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 1, 'fields' => ['type' => 'easy', 'title' => 'Mon']],
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'title' => 'Sun']],
            ]),
        ]);

        $this->assertTrue($result['requires_approval']);
        $dayDows = array_column($result['payload']['schedule']['weeks'][0]['days'], 'day_of_week');
        $this->assertContains(1, $dayDows);
        $this->assertContains(7, $dayDows);
    }

    public function test_non_array_operation_returns_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => json_encode([null]),
        ]);

        $this->assertStringContainsString('must be a JSON object', $result['error']);
    }

    public function test_empty_operations_array_returns_error(): void
    {
        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Rejected,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'operations' => '[]',
        ]);

        $this->assertStringContainsString('non-empty JSON', $result['error']);
    }

    public function test_edit_honors_user_added_day_outside_preferred_weekdays(): void
    {
        // Edits are user-driven. When the runner asks the coach to add a
        // workout on a weekday outside their original preferred list, the
        // optimizer must honor it (and auto-extend preferred_weekdays so
        // subsequent passes treat the broadened list as the new normal).
        // Strict enforcement only applies to fresh `create_schedule` calls
        // where the agent could be silently violating the runner's intent.
        $user = User::factory()->create();
        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test',
            'distance' => '10k',
            'target_date' => '2026-07-10',
            'goal_time_seconds' => 2400,
            'preferred_weekdays' => [1, 3, 5], // Mon/Wed/Fri
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'total_km' => 15,
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'title' => 'Easy', 'target_km' => 5.0],
                        ['day_of_week' => 3, 'type' => 'easy', 'title' => 'Easy', 'target_km' => 5.0],
                        ['day_of_week' => 5, 'type' => 'easy', 'title' => 'Easy', 'target_km' => 5.0],
                    ],
                ]],
            ],
        ];
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Pending,
            'payload' => $payload,
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'add_day', 'week' => 1, 'day_of_week' => 7, 'fields' => ['type' => 'easy', 'title' => 'New Sunday', 'target_km' => 5.0]],
            ]),
        ]);

        $dows = array_map(
            fn ($d) => $d['day_of_week'],
            $result['payload']['schedule']['weeks'][0]['days'],
        );
        $this->assertContains(7, $dows, 'User-added Sunday should be kept on edit.');
        $this->assertEqualsCanonicalizing([1, 3, 5, 7], $dows);
        $this->assertSame(
            [1, 3, 5, 7],
            $result['payload']['preferred_weekdays'],
            'preferred_weekdays should auto-extend to include the user-added Sunday.'
        );
    }

    public function test_edit_on_pending_proposal_does_not_attach_diff(): void
    {
        // Editing a not-yet-accepted proposal (including verify-loop fixups
        // during onboarding) produces a new pending proposal but MUST NOT
        // include a `diff` field — the runner never saw the pre-edit
        // version, so showing a "PLAN REVISION — N changes" card is
        // confusing. They should see the whole plan as fresh.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 8.0]],
            ]),
        ]);

        $this->assertSame('create_schedule', $result['proposal_type']);
        $this->assertArrayNotHasKey('diff', $result['payload']);
    }

    public function test_edit_on_active_plan_attaches_diff_for_revision_ui(): void
    {
        // When the runner has an ACTIVE plan (already accepted), editing
        // it is a genuine revision — attach the diff so the UI can show
        // "N changes to your plan" and the review sheet.
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
        ]);
        $week = TrainingWeek::factory()->for($goal)->create(['week_number' => 1]);
        TrainingDay::factory()->for($week, 'trainingWeek')->create([
            'order' => 1,
            'target_km' => 5.0,
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => null,
            'goal_id' => $goal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 1, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertSame('edit_active_plan', $result['proposal_type']);
        $this->assertArrayHasKey('diff', $result['payload']);
        $this->assertCount(1, $result['payload']['diff']);
    }

    public function test_set_day_regenerates_title_when_type_changes(): void
    {
        // When `set_day` flips a day's type without passing an explicit
        // title, the stale type label must be replaced so the UI doesn't
        // show "Tempo" on a day whose type is now `interval`.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 4, 'fields' => ['type' => 'interval', 'target_km' => 5.0]],
            ]),
        ]);

        $tuesday = collect($result['payload']['schedule']['weeks'][0]['days'])
            ->firstWhere('day_of_week', 4);
        $this->assertSame('interval', $tuesday['type']);
        $this->assertSame('Intervals', $tuesday['title']);
    }

    public function test_set_day_preserves_explicit_title(): void
    {
        // If the op DOES pass a title, that wins — stale-title regen only
        // kicks in when the AI left title out of the fields blob.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 4, 'fields' => ['type' => 'interval', 'target_km' => 5.0, 'title' => 'Hill Intervals']],
            ]),
        ]);

        $tuesday = collect($result['payload']['schedule']['weeks'][0]['days'])
            ->firstWhere('day_of_week', 4);
        $this->assertSame('Hill Intervals', $tuesday['title']);
    }

    public function test_edit_also_bumps_too_short_runs(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => [
                'avg_pace_seconds_per_km' => 342,
                'weekly_avg_km' => 10.0,
                'weekly_avg_runs' => 1,
            ],
        ]);
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 2, 'fields' => ['target_km' => 2.0]],
            ]),
        ]);

        $monday = collect($result['payload']['schedule']['weeks'][0]['days'])
            ->firstWhere('day_of_week', 2);
        $this->assertSame(4.0, (float) $monday['target_km']);
    }
}
