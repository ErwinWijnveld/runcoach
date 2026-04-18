<?php

namespace Tests\Unit;

use App\Services\OnboardingPlanPromptBuilder;
use PHPUnit\Framework\TestCase;

class OnboardingPlanPromptBuilderTest extends TestCase
{
    public function test_race_prompt_includes_core_fields(): void
    {
        $prompt = (new OnboardingPlanPromptBuilder)->build(
            goalType: 'race',
            distanceMeters: 21097,
            goalName: 'Rotterdam Half',
            targetDate: '2026-09-15',
            goalTimeSeconds: 6300,
            daysPerWeek: 4,
            coachStyle: 'balanced',
            prCurrentSeconds: null,
            profileMetrics: [
                'weekly_avg_km' => 30,
                'weekly_avg_runs' => 4,
                'avg_pace_seconds_per_km' => 300,
                'session_avg_duration_seconds' => 3600,
            ],
            todayIso: '2026-04-18',
            todayWeekday: 6,
        );

        $this->assertStringContainsString('Rotterdam Half', $prompt);
        $this->assertStringContainsString('21097', $prompt);
        $this->assertStringContainsString('2026-09-15', $prompt);
        $this->assertStringContainsString('balanced', $prompt);
        $this->assertStringContainsString('day_of_week', $prompt);
        $this->assertStringContainsString('Today is 2026-04-18', $prompt);
        $this->assertStringContainsString('EXACTLY 4 training days', $prompt);
    }

    public function test_fitness_prompt_omits_race_constraints(): void
    {
        $prompt = (new OnboardingPlanPromptBuilder)->build(
            goalType: 'fitness',
            distanceMeters: null,
            goalName: null,
            targetDate: null,
            goalTimeSeconds: null,
            daysPerWeek: 3,
            coachStyle: 'flexible',
            prCurrentSeconds: null,
            profileMetrics: [
                'weekly_avg_km' => 15,
                'weekly_avg_runs' => 3,
                'avg_pace_seconds_per_km' => 340,
                'session_avg_duration_seconds' => 2400,
            ],
            todayIso: '2026-04-18',
            todayWeekday: 6,
        );

        $this->assertStringContainsString('general fitness', $prompt);
        $this->assertStringNotContainsString('FINAL week contains', $prompt);
        $this->assertStringContainsString('EXACTLY 3 training days', $prompt);
    }

    public function test_pr_prompt_includes_current_and_target(): void
    {
        $prompt = (new OnboardingPlanPromptBuilder)->build(
            goalType: 'pr',
            distanceMeters: 10000,
            goalName: null,
            targetDate: null,
            goalTimeSeconds: 2400,
            daysPerWeek: 5,
            coachStyle: 'strict',
            prCurrentSeconds: 2700,
            profileMetrics: [
                'weekly_avg_km' => 40,
                'weekly_avg_runs' => 5,
                'avg_pace_seconds_per_km' => 270,
                'session_avg_duration_seconds' => 3000,
            ],
            todayIso: '2026-04-18',
            todayWeekday: 6,
        );

        $this->assertStringContainsString('improve their PR at 10000m', $prompt);
        $this->assertStringContainsString('Current PR: 2700 seconds', $prompt);
        $this->assertStringContainsString('Target: 2400 seconds', $prompt);
    }
}
