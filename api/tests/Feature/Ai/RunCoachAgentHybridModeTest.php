<?php

namespace Tests\Feature\Ai;

use App\Ai\Agents\RunCoachAgent;
use App\Ai\Tools\CreateSchedule;
use App\Ai\Tools\EditSchedule;
use App\Ai\Tools\VerifyPlan;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RunCoachAgentHybridModeTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_solo_user_gets_full_tool_set_including_plan_mutations(): void
    {
        $user = User::factory()->create();

        $tools = iterator_to_array(RunCoachAgent::make($user)->tools());
        $classes = array_map('get_class', $tools);

        $this->assertContains(CreateSchedule::class, $classes);
        $this->assertContains(EditSchedule::class, $classes);
        $this->assertContains(VerifyPlan::class, $classes);
    }

    public function test_coached_client_does_not_get_plan_mutation_tools(): void
    {
        $org = Organization::factory()->create(['coaches_own_plans' => true]);
        $user = User::factory()->create();
        OrganizationMembership::factory()->client()->for($org)->for($user)->create();

        $tools = iterator_to_array(RunCoachAgent::make($user->refresh())->tools());
        $classes = array_map('get_class', $tools);

        $this->assertNotContains(CreateSchedule::class, $classes);
        $this->assertNotContains(EditSchedule::class, $classes);
        $this->assertNotContains(VerifyPlan::class, $classes);
    }

    public function test_client_in_org_with_coaches_own_plans_off_keeps_plan_tools(): void
    {
        $org = Organization::factory()->create(['coaches_own_plans' => false]);
        $user = User::factory()->create();
        OrganizationMembership::factory()->client()->for($org)->for($user)->create();

        $tools = iterator_to_array(RunCoachAgent::make($user->refresh())->tools());
        $classes = array_map('get_class', $tools);

        $this->assertContains(CreateSchedule::class, $classes);
    }

    public function test_coach_role_in_org_keeps_plan_tools(): void
    {
        $org = Organization::factory()->create(['coaches_own_plans' => true]);
        $user = User::factory()->create();
        OrganizationMembership::factory()->coach()->for($org)->for($user)->create();

        $tools = iterator_to_array(RunCoachAgent::make($user->refresh())->tools());
        $classes = array_map('get_class', $tools);

        // Coaches/admins are not the audience for the AI plan-mutation gate;
        // they manage plans through the coach panel. The gate applies only
        // to the client role.
        $this->assertContains(CreateSchedule::class, $classes);
    }
}
