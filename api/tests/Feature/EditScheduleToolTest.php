<?php

namespace Tests\Feature;

use App\Ai\Tools\EditSchedule;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
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
            'preferred_weekdays' => [2, 4, 6],
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
        $tool = new EditSchedule($user);
        $result = $tool->handle(new Request($input));

        return json_decode($result, true);
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

        $this->assertCount(4, $result['payload']['schedule']['weeks'][0]['days']);
        $this->assertEquals(24.0, $result['payload']['schedule']['weeks'][0]['total_km']);
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

    public function test_pending_source_is_not_superseded_by_tool_handler(): void
    {
        // Supersede now happens in ProposalService when the NEW proposal is persisted,
        // so a stream failure after the tool returns can't orphan the pending source.
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $this->invoke($user, [
            'proposal_id' => $proposal->id,
            'operations' => json_encode([
                ['op' => 'set_day', 'week' => 1, 'day_of_week' => 6, 'fields' => ['target_km' => 7.0]],
            ]),
        ]);

        $this->assertSame(ProposalStatus::Pending, $proposal->fresh()->status);
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
}
