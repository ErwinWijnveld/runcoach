<?php

namespace App\Services;

class OnboardingPlanPromptBuilder
{
    /**
     * Build a prompt for the onboarding plan generator.
     *
     * The prompt asks the model to output a pure JSON object matching the
     * `CreateSchedule` tool's payload shape (weeks → days with day_of_week 1-7),
     * which is the format `ProposalService::applyCreateSchedule` expects.
     *
     * @param  array<string, mixed>  $profileMetrics
     */
    public function build(
        string $goalType,
        ?int $distanceMeters,
        ?string $goalName,
        ?string $targetDate,
        ?int $goalTimeSeconds,
        int $daysPerWeek,
        string $coachStyle,
        ?int $prCurrentSeconds,
        array $profileMetrics,
        string $todayIso,
        int $todayWeekday,
    ): string {
        $lines = [];
        $lines[] = 'You are generating a running training plan. Output ONLY a JSON object matching this schema — no prose, no markdown fences:';
        $lines[] = <<<'JSON'
{
  "weeks": [
    {
      "week_number": 1,
      "total_km": number,
      "focus": "short phrase, e.g. Base building",
      "days": [
        {
          "day_of_week": 1,
          "type": "easy|tempo|interval|long_run|recovery",
          "title": "short label",
          "description": "1-2 sentence coaching note",
          "target_km": number|null,
          "target_pace_seconds_per_km": number|null,
          "target_heart_rate_zone": "Z1|Z2|Z3|Z4|Z5"|null
        }
      ]
    }
  ]
}
JSON;
        $lines[] = '';
        $lines[] = 'Hard constraints:';
        $lines[] = "- Today is {$todayIso} (ISO weekday {$todayWeekday}, where 1=Mon…7=Sun).";
        $lines[] = "- Week 1 represents THIS calendar week. Do NOT emit any day whose `day_of_week` is earlier than {$todayWeekday}; the runner cannot train in the past.";
        $lines[] = "- Each week contains EXACTLY {$daysPerWeek} training days. Skip the other days entirely (do NOT emit rest days).";
        $lines[] = "- Coaching style: {$coachStyle}. Reflect this in tone and volume progression (strict = tight, flexible = forgiving).";
        $lines[] = '- Allowed `type` values: easy, tempo, interval, long_run, recovery. Nothing else.';

        if ($goalType === 'race' && $targetDate && $distanceMeters) {
            $name = $goalName ?: 'Race day';
            $lines[] = "- The user is training for a race: {$name} ({$distanceMeters}m) on {$targetDate}.";
            if ($goalTimeSeconds) {
                $goalPace = (int) round($goalTimeSeconds / ($distanceMeters / 1000));
                $lines[] = "- Goal finish time: {$goalTimeSeconds} seconds (≈{$goalPace} sec/km).";
            }
            $lines[] = "- Size total weeks so the FINAL week contains {$targetDate}. That final week MUST include exactly one training day on {$targetDate}'s ISO weekday with:";
            $lines[] = "  - title = \"{$name}\", type = \"tempo\" (or \"long_run\" for pure distance goals)";
            $lines[] = '  - target_km = '.($distanceMeters / 1000);
            if ($goalTimeSeconds) {
                $goalPace = (int) round($goalTimeSeconds / ($distanceMeters / 1000));
                $lines[] = "  - target_pace_seconds_per_km = {$goalPace}";
            }
            $lines[] = '  - description = "Goal day. Execute your plan."';
            $lines[] = '  - never schedule any other training on this day';
        } elseif ($goalType === 'pr' && $distanceMeters && $goalTimeSeconds) {
            $goalPace = (int) round($goalTimeSeconds / ($distanceMeters / 1000));
            $lines[] = "- The user wants to improve their PR at {$distanceMeters}m. Target: {$goalTimeSeconds} seconds (≈{$goalPace} sec/km).";
            if ($prCurrentSeconds) {
                $currentPace = (int) round($prCurrentSeconds / ($distanceMeters / 1000));
                $lines[] = "- Current PR: {$prCurrentSeconds} seconds (≈{$currentPace} sec/km).";
            }
            $lines[] = '- Generate 8 weeks of progression ending with a race-pace test.';
        } else {
            $lines[] = '- The user is training for general fitness (no specific race). Generate 6 weeks of sustainable progression.';
        }

        $lines[] = '';
        $lines[] = "Current runner profile (last 12 months, use THESE numbers — don't invent):";
        $lines[] = '- Average weekly km: '.($profileMetrics['weekly_avg_km'] ?? 0);
        $lines[] = '- Average runs per week: '.($profileMetrics['weekly_avg_runs'] ?? 0);
        $lines[] = '- Average pace: '.($profileMetrics['avg_pace_seconds_per_km'] ?? 0).' sec/km';
        $lines[] = '- Average session duration: '.($profileMetrics['session_avg_duration_seconds'] ?? 0).' seconds';

        $lines[] = '';
        $lines[] = 'Coaching principles to apply (pick 3-5 most relevant):';
        $lines[] = '- Polarized 80/20: ~80% easy conversational, ~20% quality.';
        $lines[] = '- Progressive overload: cap weekly volume growth at ~10%.';
        $lines[] = '- Periodization: base → build → peak → taper (race only).';
        $lines[] = '- Cutback every 3-4 weeks (~25% volume drop).';
        $lines[] = "- Individualization: build on the runner's current volume and pace, not textbook defaults.";

        $lines[] = '';
        $lines[] = 'Output ONLY the JSON object. No prose before or after. No markdown code fences.';

        return implode("\n", $lines);
    }
}
