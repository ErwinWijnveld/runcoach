<?php

namespace App\Services;

use App\Enums\TrainingType;

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
     * @param  array<int, int>|null  $preferredWeekdays  ISO weekdays (1=Mon…7=Sun) the runner can train.
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
        ?array $preferredWeekdays = null,
        ?string $additionalNotes = null,
    ): string {
        $trainingTypes = TrainingType::activeValuesAsPipe();
        $trainingTypeCsv = implode(', ', TrainingType::activeValues());

        $lines = [];
        $lines[] = 'You are generating a running training plan. Output ONLY a JSON object matching this schema — no prose, no markdown fences:';
        $lines[] = <<<JSON
{
  "weeks": [
    {
      "week_number": 1,
      "total_km": number,
      "focus": "short phrase, e.g. Base building",
      "days": [
        {
          "day_of_week": 1,
          "type": "{$trainingTypes}",
          "title": "short label",
          "description": "1-2 sentence coaching note",
          "target_km": number|null,
          "target_pace_seconds_per_km": number|null,
          "target_heart_rate_zone": integer 1-5 (not "Z1" or "z1" - use the plain integer)|null
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
        if (is_array($preferredWeekdays) && count($preferredWeekdays) > 0) {
            $names = [1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu', 5 => 'Fri', 6 => 'Sat', 7 => 'Sun'];
            $sorted = $preferredWeekdays;
            sort($sorted);
            $labels = implode(', ', array_map(fn ($d) => $names[$d] ?? (string) $d, $sorted));
            $csv = implode(', ', $sorted);
            $lines[] = "- The runner can ONLY run on these ISO weekdays: [{$csv}] ({$labels}). Every training day's `day_of_week` MUST be one of these values. Do not schedule runs on any other weekday.";
        }
        $lines[] = "- Coaching style: {$coachStyle}. Reflect this in tone and volume progression (strict = tight, flexible = forgiving).";
        $lines[] = "- Allowed `type` values: {$trainingTypeCsv}. Nothing else. Use `easy` for low-intensity shakeout / recovery runs — there is no separate \"recovery\" type.";

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
        } elseif ($goalType === 'weight_loss') {
            $lines[] = '- The user is training primarily for weight loss. Prioritise consistent, sustainable calorie burn: lean heavy on easy-effort volume (Z2), stack gradual long-run progression, and keep high-intensity sessions limited to 1 per week to preserve recovery. Generate 8 weeks of steady progression.';
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

        if (is_string($additionalNotes) && trim($additionalNotes) !== '') {
            $lines[] = '';
            $lines[] = 'Additional notes from the runner (factor these in where reasonable, but never violate the hard constraints above):';
            $lines[] = '"'.trim($additionalNotes).'"';
        }

        $lines[] = '';
        $lines[] = 'Output ONLY the JSON object. No prose before or after. No markdown code fences.';

        return implode("\n", $lines);
    }
}
