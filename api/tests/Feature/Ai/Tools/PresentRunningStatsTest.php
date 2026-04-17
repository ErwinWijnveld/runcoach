<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\PresentRunningStats;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\JsonSchema\JsonSchemaTypeFactory;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class PresentRunningStatsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_stats_card_payload(): void
    {
        $user = User::factory()->create();
        $tool = new PresentRunningStats($user);

        $request = new Request([
            'weekly_avg_km' => 25.0,
            'weekly_avg_runs' => 3,
            'avg_pace_seconds_per_km' => 295,
            'session_avg_duration_seconds' => 2700,
        ]);

        $raw = $tool->handle($request);
        $decoded = json_decode($raw, true);

        $this->assertEquals('stats_card', $decoded['display']);
        $this->assertEquals(25.0, $decoded['metrics']['weekly_avg_km']);
        $this->assertEquals(3, $decoded['metrics']['weekly_avg_runs']);
    }

    public function test_schema_declares_all_four_metric_params(): void
    {
        $user = User::factory()->create();
        $tool = new PresentRunningStats($user);
        $schema = $tool->schema(new JsonSchemaTypeFactory);

        $names = array_keys($schema);
        sort($names);
        $this->assertEquals(
            ['avg_pace_seconds_per_km', 'session_avg_duration_seconds', 'weekly_avg_km', 'weekly_avg_runs'],
            $names,
        );
    }
}
