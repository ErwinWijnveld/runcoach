<?php

namespace Tests\Feature\Services;

use App\Ai\Agents\RunningNarrativeAgent;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use App\Services\Strava\StravaClient;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class RunningProfileServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_analyze_computes_metrics_from_strava_activities(): void
    {
        $user = User::factory()->create();

        // Fake 52 weeks, 3 runs per week, 10km each at 5:00/km pace
        $activities = [];
        for ($week = 0; $week < 52; $week++) {
            for ($run = 0; $run < 3; $run++) {
                $activities[] = [
                    'type' => 'Run',
                    'distance' => 10_000,
                    'moving_time' => 3000,
                    'start_date' => now()->subWeeks(52 - $week)->subDays($run)->toIso8601String(),
                    'elapsed_time' => 3000,
                ];
            }
        }

        $client = Mockery::mock(StravaClient::class);

        $service = new RunningProfileService($client);
        $profile = $service->computeMetrics($user, $activities);

        $this->assertInstanceOf(UserRunningProfile::class, $profile);
        $this->assertEquals(30.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(3, $profile->metrics['weekly_avg_runs']);
        $this->assertEquals(300, $profile->metrics['avg_pace_seconds_per_km']);
        $this->assertEquals(3000, $profile->metrics['session_avg_duration_seconds']);
        $this->assertEquals(156, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(1560.0, $profile->metrics['total_distance_km_12mo']);
        $this->assertEquals(100, $profile->metrics['consistency_score']);
    }

    public function test_analyze_handles_zero_activities(): void
    {
        $user = User::factory()->create();

        $client = Mockery::mock(StravaClient::class);

        $service = new RunningProfileService($client);
        $profile = $service->computeMetrics($user, []);

        $this->assertEquals(0, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(0.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(0, $profile->metrics['consistency_score']);
    }

    public function test_generate_narrative_uses_agent_with_metrics_context(): void
    {
        $metrics = [
            'weekly_avg_km' => 25.0,
            'weekly_avg_runs' => 3,
            'consistency_score' => 85,
            'long_run_trend' => 'improving',
            'pace_trend' => 'flat',
        ];

        $receivedPrompt = null;
        RunningNarrativeAgent::fake([
            function (string $prompt) use (&$receivedPrompt) {
                $receivedPrompt = $prompt;

                return 'Strong consistent year.';
            },
        ]);

        $service = new RunningProfileService(app(StravaClient::class));
        $narrative = $service->generateNarrativePublic($metrics);

        $this->assertEquals('Strong consistent year.', $narrative);
        $this->assertStringContainsString((string) $metrics['weekly_avg_km'], $receivedPrompt);
        $this->assertStringContainsString('improving', $receivedPrompt);
    }

    public function test_generate_narrative_falls_back_on_agent_failure(): void
    {
        RunningNarrativeAgent::fake([
            function (): never {
                throw new \Exception('API down');
            },
        ]);

        $service = new RunningProfileService(app(StravaClient::class));
        $narrative = $service->generateNarrativePublic(['weekly_avg_km' => 10]);

        $this->assertEquals("Here's your last 12 months.", $narrative);
    }
}
