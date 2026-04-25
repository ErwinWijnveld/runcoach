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

/**
 * After the refactor where CreateSchedule/EditSchedule persist their own
 * proposals mid-loop, `detectProposalFromConversation` is no longer
 * responsible for creating proposals — it just backfills the
 * `agent_message_id` FK on the existing pending proposal to the latest
 * assistant message in the conversation.
 */
class ProposalServiceDetectionTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function seedAssistantMessage(string $conversationId, User $user): string
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
            'tool_results' => '[]',
            'usage' => '{}',
            'meta' => '{}',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $messageId;
    }

    public function test_backfills_agent_message_id_on_pending_proposal(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();
        $messageId = $this->seedAssistantMessage($convId, $user);

        $pending = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'agent_message_id' => null,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $returned = app(ProposalService::class)->detectProposalFromConversation($user, $convId);

        $this->assertNotNull($returned);
        $this->assertSame($pending->id, $returned->id);
        $this->assertSame($messageId, $pending->fresh()->agent_message_id);
    }

    public function test_returns_null_when_no_pending_proposal_exists(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();
        $this->seedAssistantMessage($convId, $user);

        $this->assertNull(
            app(ProposalService::class)->detectProposalFromConversation($user, $convId)
        );
    }

    public function test_returns_null_when_no_assistant_message_exists(): void
    {
        $user = User::factory()->create();

        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'agent_message_id' => null,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $this->assertNull(
            app(ProposalService::class)->detectProposalFromConversation($user, (string) Str::uuid())
        );
    }

    public function test_leaves_already_linked_proposal_untouched(): void
    {
        $user = User::factory()->create();
        $convId = (string) Str::uuid();
        $this->seedAssistantMessage($convId, $user);
        $originalLink = (string) Str::uuid();

        $pending = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'agent_message_id' => $originalLink,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        app(ProposalService::class)->detectProposalFromConversation($user, $convId);

        $this->assertSame($originalLink, $pending->fresh()->agent_message_id);
    }

    public function test_ignores_other_users_pending_proposals(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $convId = (string) Str::uuid();
        $this->seedAssistantMessage($convId, $user);

        CoachProposal::factory()->create([
            'user_id' => $other->id,
            'agent_message_id' => null,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => ['schedule' => ['weeks' => []]],
        ]);

        $this->assertNull(
            app(ProposalService::class)->detectProposalFromConversation($user, $convId)
        );
    }
}
