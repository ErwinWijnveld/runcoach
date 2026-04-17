<?php

namespace Tests\Feature\Listeners;

use App\Ai\Agents\PlanExplanationAgent;
use App\Ai\Agents\RunCoachAgent;
use App\Listeners\RecordAgentTokenUsage;
use App\Models\TokenUsage;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Ai\Contracts\Providers\TextProvider;
use Laravel\Ai\Events\AgentPrompted;
use Laravel\Ai\Prompts\AgentPrompt;
use Laravel\Ai\Responses\AgentResponse;
use Laravel\Ai\Responses\Data\Meta;
use Laravel\Ai\Responses\Data\Usage;
use Mockery;
use Tests\TestCase;

class RecordAgentTokenUsageTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_records_token_usage_for_run_coach_agent_in_onboarding_context(): void
    {
        $user = User::factory()->create();
        $conversationId = Str::uuid()->toString();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Test',
            'context' => 'onboarding',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $agent = RunCoachAgent::make(user: $user)->continue($conversationId, as: $user);
        $event = $this->makeEvent($agent, promptTokens: 100, completionTokens: 50);

        (new RecordAgentTokenUsage)->handle($event);

        $row = TokenUsage::firstOrFail();
        $this->assertSame($user->id, $row->user_id);
        $this->assertSame($conversationId, $row->conversation_id);
        $this->assertSame('onboarding', $row->context);
        $this->assertSame(RunCoachAgent::class, $row->agent_class);
        $this->assertSame(100, $row->prompt_tokens);
        $this->assertSame(50, $row->completion_tokens);
        $this->assertSame(150, $row->total_tokens);
    }

    public function test_records_plan_explanation_agent_as_plan_explanation_context_without_user(): void
    {
        $agent = new PlanExplanationAgent;
        $event = $this->makeEvent($agent, promptTokens: 200, completionTokens: 80);

        (new RecordAgentTokenUsage)->handle($event);

        $row = TokenUsage::firstOrFail();
        $this->assertNull($row->user_id);
        $this->assertNull($row->conversation_id);
        $this->assertSame('plan_explanation', $row->context);
        $this->assertSame(280, $row->total_tokens);
    }

    public function test_skips_when_no_usage_or_zero_tokens(): void
    {
        $agent = new PlanExplanationAgent;
        $event = $this->makeEvent($agent, promptTokens: 0, completionTokens: 0);

        (new RecordAgentTokenUsage)->handle($event);

        $this->assertSame(0, TokenUsage::count());
    }

    private function makeEvent(object $agent, int $promptTokens, int $completionTokens): AgentPrompted
    {
        $provider = Mockery::mock(TextProvider::class);

        $prompt = new AgentPrompt($agent, 'test', [], $provider, 'claude-sonnet-4-6');
        $response = new AgentResponse(
            Str::uuid()->toString(),
            'ok',
            new Usage($promptTokens, $completionTokens),
            new Meta('anthropic', 'claude-sonnet-4-6'),
        );

        return new AgentPrompted(Str::uuid()->toString(), $prompt, $response);
    }
}
