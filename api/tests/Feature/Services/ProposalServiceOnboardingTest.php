<?php

namespace Tests\Feature\Services;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class ProposalServiceOnboardingTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function insertConversation(string $conversationId, string $context): void
    {
        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => null,
            'title' => 'Onboarding',
            'context' => $context,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function insertMessage(string $messageId, string $conversationId): void
    {
        DB::table('agent_conversation_messages')->insert([
            'id' => $messageId,
            'conversation_id' => $conversationId,
            'user_id' => null,
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => '',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '{}',
            'meta' => '{}',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function minimalSchedulePayload(): array
    {
        return [
            'goal_type' => 'general_fitness',
            'goal_name' => 'Onboarding Plan',
            'target_date' => null,
            'distance' => null,
            'goal_time_seconds' => null,
            'schedule' => ['weeks' => []],
        ];
    }

    public function test_accepting_proposal_from_onboarding_conversation_marks_user_onboarding_complete(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);

        $conversationId = Str::uuid()->toString();
        $messageId = Str::uuid()->toString();

        $this->insertConversation($conversationId, 'onboarding');
        $this->insertMessage($messageId, $conversationId);

        $proposal = CoachProposal::create([
            'agent_message_id' => $messageId,
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => $this->minimalSchedulePayload(),
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $this->assertTrue($user->fresh()->has_completed_onboarding);
    }

    public function test_accepting_proposal_from_non_onboarding_conversation_does_not_flip_flag(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);

        $conversationId = Str::uuid()->toString();
        $messageId = Str::uuid()->toString();

        $this->insertConversation($conversationId, 'regular');
        $this->insertMessage($messageId, $conversationId);

        $proposal = CoachProposal::create([
            'agent_message_id' => $messageId,
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => $this->minimalSchedulePayload(),
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $this->assertFalse($user->fresh()->has_completed_onboarding);
    }

    public function test_accepting_proposal_with_no_linked_conversation_does_not_flip_flag(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);

        $proposal = CoachProposal::create([
            'agent_message_id' => Str::uuid()->toString(), // no matching message in DB
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => $this->minimalSchedulePayload(),
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $this->assertFalse($user->fresh()->has_completed_onboarding);
    }

    public function test_already_onboarded_user_is_not_re_saved(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => true]);

        $conversationId = Str::uuid()->toString();
        $messageId = Str::uuid()->toString();

        $this->insertConversation($conversationId, 'onboarding');
        $this->insertMessage($messageId, $conversationId);

        $proposal = CoachProposal::create([
            'agent_message_id' => $messageId,
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => $this->minimalSchedulePayload(),
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        // Should not throw — just a no-op
        app(ProposalService::class)->apply($proposal, $user);

        $this->assertTrue($user->fresh()->has_completed_onboarding);
    }
}
