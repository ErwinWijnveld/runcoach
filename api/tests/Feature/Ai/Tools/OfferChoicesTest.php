<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\OfferChoices;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class OfferChoicesTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_chip_suggestions_payload(): void
    {
        $user = User::factory()->create();
        $tool = new OfferChoices($user);

        $request = new Request([
            'chips' => [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
            ],
        ]);

        $raw = $tool->handle($request);
        $decoded = json_decode($raw, true);

        $this->assertEquals('chip_suggestions', $decoded['display']);
        $this->assertCount(3, $decoded['chips']);
        $this->assertEquals('race', $decoded['chips'][0]['value']);
    }
}
