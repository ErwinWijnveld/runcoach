<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\ProposeNewPlanCard;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class ProposeNewPlanCardTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_emits_card_display_payload(): void
    {
        $user = User::factory()->create();
        $tool = new ProposeNewPlanCard($user);

        $result = json_decode($tool->handle(new Request([])), true);

        $this->assertSame('new_plan_card', $result['display']);
        $this->assertSame('goal_type', $result['entry_point']);
    }
}
