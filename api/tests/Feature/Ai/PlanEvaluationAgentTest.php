<?php

namespace Tests\Feature\Ai;

use App\Ai\Agents\PlanEvaluationAgent;
use App\Ai\Tools\AdjustPlan;
use App\Ai\Tools\GetComplianceReport;
use App\Ai\Tools\GetCurrentSchedule;
use App\Ai\Tools\GetRecentRuns;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class PlanEvaluationAgentTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_self_managed_user_gets_adjust_plan_in_tools(): void
    {
        $user = User::factory()->create();

        $tools = iterator_to_array(PlanEvaluationAgent::make($user)->tools());
        $classes = array_map('get_class', $tools);

        $this->assertContains(GetRecentRuns::class, $classes);
        $this->assertContains(GetComplianceReport::class, $classes);
        $this->assertContains(GetCurrentSchedule::class, $classes);
        $this->assertContains(AdjustPlan::class, $classes);
    }

    public function test_coach_managed_client_loses_adjust_plan_tool(): void
    {
        $org = Organization::factory()->create(['coaches_own_plans' => true]);
        $user = User::factory()->create();
        OrganizationMembership::factory()->client()->for($org)->for($user)->create();

        $tools = iterator_to_array(PlanEvaluationAgent::make($user->refresh())->tools());
        $classes = array_map('get_class', $tools);

        $this->assertContains(GetRecentRuns::class, $classes);
        $this->assertContains(GetComplianceReport::class, $classes);
        $this->assertContains(GetCurrentSchedule::class, $classes);
        $this->assertNotContains(AdjustPlan::class, $classes);
    }

    public function test_client_in_org_without_coaches_own_plans_keeps_adjust_plan(): void
    {
        $org = Organization::factory()->create(['coaches_own_plans' => false]);
        $user = User::factory()->create();
        OrganizationMembership::factory()->client()->for($org)->for($user)->create();

        $tools = iterator_to_array(PlanEvaluationAgent::make($user->refresh())->tools());
        $classes = array_map('get_class', $tools);

        $this->assertContains(AdjustPlan::class, $classes);
    }
}
