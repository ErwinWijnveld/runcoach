<?php

namespace Tests\Feature;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class ProposalServiceDetectionTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function seedAssistantMessage(string $conversationId, User $user, array $toolResults): string
    {
        $messageId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Test',
            'context' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('agent_conversation_messages')->insert([
            'id' => $messageId,
            'conversation_id' => $conversationId,
            'user_id' => $user->id,
            'agent' => 'App\\Ai\\Agents\\RunCoachAgent',
            'role' => 'assistant',
            'content' => 'test',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => json_encode($toolResults),
            'usage' => '{}',
            'meta' => '{}',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $messageId;
    }

    public function test_last_requires_approval_tool_result_wins(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();

        $this->seedAssistantMessage($convId, $user, [
            [
                'tool_name' => 'edit_schedule',
                'result' => [
                    'requires_approval' => true,
                    'proposal_type' => 'create_schedule',
                    'payload' => ['goal_name' => 'FIRST', 'schedule' => ['weeks' => []]],
                ],
            ],
            [
                'tool_name' => 'edit_schedule',
                'result' => [
                    'requires_approval' => true,
                    'proposal_type' => 'create_schedule',
                    'payload' => ['goal_name' => 'SECOND', 'schedule' => ['weeks' => []]],
                ],
            ],
        ]);

        $proposal = app(ProposalService::class)->detectProposalFromConversation($user, $convId);

        $this->assertNotNull($proposal);
        $this->assertSame('SECOND', $proposal->payload['goal_name']);
    }

    public function test_detection_supersedes_other_pending_proposals(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();

        $oldPending = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $this->seedAssistantMessage($convId, $user, [[
            'tool_name' => 'edit_schedule',
            'result' => [
                'requires_approval' => true,
                'proposal_type' => 'create_schedule',
                'payload' => ['goal_name' => 'Revised', 'schedule' => ['weeks' => []]],
            ],
        ]]);

        $newProposal = app(ProposalService::class)->detectProposalFromConversation($user, $convId);

        $this->assertNotNull($newProposal);
        $this->assertSame(ProposalStatus::Pending, $newProposal->status);
        $this->assertSame(ProposalStatus::Rejected, $oldPending->fresh()->status);
    }

    public function test_detection_leaves_other_users_proposals_untouched(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $convId = (string) Str::uuid();

        $otherPending = CoachProposal::factory()->create([
            'user_id' => $other->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $this->seedAssistantMessage($convId, $user, [[
            'tool_name' => 'edit_schedule',
            'result' => [
                'requires_approval' => true,
                'proposal_type' => 'create_schedule',
                'payload' => ['schedule' => ['weeks' => []]],
            ],
        ]]);

        app(ProposalService::class)->detectProposalFromConversation($user, $convId);

        $this->assertSame(ProposalStatus::Pending, $otherPending->fresh()->status);
    }

    public function test_detection_returns_null_when_no_tool_result_requires_approval(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();

        $this->seedAssistantMessage($convId, $user, [[
            'tool_name' => 'get_recent_runs',
            'result' => ['runs' => []],
        ]]);

        $this->assertNull(app(ProposalService::class)->detectProposalFromConversation($user, $convId));
    }
}
