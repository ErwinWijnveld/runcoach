<?php

namespace Tests\Feature;

use App\Ai\Agents\PlanVerifierAgent;
use App\Ai\Tools\VerifyPlan;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class VerifyPlanToolTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_error_when_no_proposal_or_active_plan(): void
    {
        PlanVerifierAgent::fake(['{"passed":true,"summary":"ok","issues":[]}']);
        $user = User::factory()->create();

        $result = $this->invoke($user);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_returns_verifier_verdict_for_pending_proposal(): void
    {
        PlanVerifierAgent::fake([
            '{"passed":true,"summary":"Plan looks solid.","issues":[]}',
        ]);

        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user);

        $this->assertTrue($result['passed']);
        $this->assertSame('Plan looks solid.', $result['summary']);
        $this->assertSame([], $result['issues']);
        $this->assertSame('pending_proposal', $result['source']);
        $this->assertSame(2, $result['max_cycles']);
        $this->assertSame(1, $result['cycle']);
    }

    public function test_hard_caps_at_max_cycles_across_edits_within_same_generation(): void
    {
        // The counter is keyed to the user and survives proposal churn —
        // `edit_schedule` supersedes the pending proposal on every call,
        // so a per-proposal counter would reset every turn and the cap
        // would never fire. This test proves the cap holds across 3+
        // superseding proposals within the same generation session.
        PlanVerifierAgent::fake([
            '{"passed":false,"summary":"still failing","issues":[]}',
            '{"passed":false,"summary":"still failing","issues":[]}',
            '{"passed":false,"summary":"would be third call","issues":[]}',
        ]);

        $user = User::factory()->create();
        $this->newPendingProposal($user);

        $first = $this->invoke($user);
        $this->assertSame(1, $first['cycle']);
        $this->assertFalse($first['passed']);
        $this->assertArrayNotHasKey('capped', $first);

        // Simulate an edit_schedule superseding the proposal.
        $this->newPendingProposal($user);

        $second = $this->invoke($user);
        $this->assertSame(2, $second['cycle']);
        $this->assertFalse($second['passed']);

        // Another edit → new proposal → counter should NOT reset.
        $this->newPendingProposal($user);

        $third = $this->invoke($user);
        $this->assertSame(3, $third['cycle']);
        $this->assertTrue($third['passed']);
        $this->assertTrue($third['capped']);
        $this->assertStringContainsString('Max verification', $third['summary']);
    }

    public function test_cycle_counter_resets_when_create_schedule_runs(): void
    {
        // The cap exists for the duration of ONE generation session. A
        // brand-new `create_schedule` call (new plan from scratch) clears
        // the counter — that's handled in CreateSchedule::handle. This
        // test simulates that by flushing the counter key directly.
        PlanVerifierAgent::fake([
            '{"passed":false,"summary":"fail","issues":[]}',
            '{"passed":false,"summary":"fail","issues":[]}',
        ]);

        $user = User::factory()->create();
        $this->newPendingProposal($user);

        $this->invoke($user);
        $this->invoke($user);

        // Simulate CreateSchedule resetting the counter.
        Cache::forget(VerifyPlan::cycleCacheKey($user->id));

        PlanVerifierAgent::fake(['{"passed":true,"summary":"fresh","issues":[]}']);
        $fresh = $this->invoke($user);
        $this->assertSame(1, $fresh['cycle']);
        $this->assertTrue($fresh['passed']);
    }

    private function newPendingProposal(User $user): CoachProposal
    {
        return CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);
    }

    public function test_audits_edit_active_plan_proposals_not_just_create(): void
    {
        PlanVerifierAgent::fake(['{"passed":true,"summary":"edit ok","issues":[]}']);

        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::EditActivePlan,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user);

        $this->assertTrue($result['passed']);
        $this->assertSame('pending_proposal', $result['source']);
    }

    public function test_normalizes_issues_and_surfaces_them(): void
    {
        PlanVerifierAgent::fake([
            json_encode([
                'passed' => false,
                'summary' => 'Week 1 volume too high.',
                'issues' => [
                    [
                        'severity' => 'major',
                        'area' => 'volume',
                        'week' => 1,
                        'day_of_week' => null,
                        'description' => 'Week 1 is 45 km vs runner avg 18 km (+150%).',
                        'suggested_fix' => 'set_day ops to halve target_km on each week-1 day',
                    ],
                ],
            ]),
        ]);

        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user);

        $this->assertFalse($result['passed']);
        $this->assertSame('major', $result['issues'][0]['severity']);
        $this->assertSame('volume', $result['issues'][0]['area']);
        $this->assertSame(1, $result['issues'][0]['week']);
    }

    public function test_strips_markdown_code_fences_from_verifier_output(): void
    {
        PlanVerifierAgent::fake([
            "```json\n{\"passed\":true,\"summary\":\"fenced but fine\",\"issues\":[]}\n```",
        ]);

        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user);

        $this->assertTrue($result['passed']);
        $this->assertSame('fenced but fine', $result['summary']);
    }

    public function test_falls_back_to_pass_when_verifier_returns_garbage(): void
    {
        PlanVerifierAgent::fake(['not a json response at all']);

        $user = User::factory()->create();
        CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
            'payload' => $this->samplePayload(),
        ]);

        $result = $this->invoke($user);

        $this->assertTrue($result['passed']);
        $this->assertStringContainsString('unparseable', $result['summary']);
    }

    /**
     * @return array<string, mixed>
     */
    private function invoke(User $user): array
    {
        $tool = new VerifyPlan($user);
        $raw = $tool->handle(new Request([]));

        return json_decode($raw, true);
    }

    /**
     * @return array<string, mixed>
     */
    private function samplePayload(): array
    {
        return [
            'goal_type' => 'race',
            'goal_name' => 'Test Race',
            'distance' => '10k',
            'target_date' => '2026-06-30',
            'goal_time_seconds' => 2700,
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'total_km' => 18.0,
                    'days' => [
                        ['day_of_week' => 2, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 4, 'type' => 'tempo', 'target_km' => 5.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 8.0],
                    ],
                ]],
            ],
        ];
    }
}
