<?php

namespace App\Ai\Tools;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class CreateSchedule implements Tool
{
    public function description(): string
    {
        return <<<'DESC'
        Create a complete training schedule for a race. Returns a proposal the runner must approve.

        IMPORTANT: Before calling this tool, you should have already:
        1. Asked the runner about their race (distance, date, goal)
        2. Fetched their recent Strava data with search_strava_activities
        3. Analyzed their fitness level and discussed your approach
        4. Gotten confirmation from the runner

        The schedule must be based on the runner's actual fitness data. Generate a realistic, week-by-week plan with specific sessions for each day. Use periodization, 80/20 rule, and progressive overload. Pace targets should be derived from their current running pace.

        The schedule parameter must be a valid JSON string containing the full plan structure.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_name' => $schema->string()->required()->description('Name of the race (e.g. "Amsterdam Marathon 2026")'),
            'distance' => $schema->string()->enum(['5k', '10k', 'half_marathon', 'marathon', 'custom'])->required(),
            'goal_time_seconds' => $schema->integer()->required()->nullable()->description('Target finish time in seconds (e.g. 5400 for 1:30:00), or null if no specific goal'),
            'race_date' => $schema->string()->required()->description('Race date in YYYY-MM-DD format'),
            'schedule' => $schema->string()->required()->description('Complete training schedule as JSON: {"weeks": [{"week_number": 1, "focus": "base building", "total_km": 30.0, "days": [{"day_of_week": 1, "type": "easy|tempo|interval|long_run|recovery|rest|mobility", "title": "Easy Run", "description": "Keep conversational pace", "target_km": 5.0, "target_pace_seconds_per_km": 390, "target_heart_rate_zone": 2}]}]}. day_of_week: 1=Monday through 7=Sunday. Include all 7 days per week (rest days too with type "rest").'),
        ];
    }

    public function handle(Request $request): string
    {
        $schedule = json_decode($request['schedule'], true);

        if (! $schedule || ! isset($schedule['weeks'])) {
            return json_encode(['error' => 'Invalid schedule JSON. Must contain a "weeks" array.']);
        }

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => 'create_schedule',
            'payload' => [
                'race_name' => $request['race_name'],
                'distance' => $request['distance'],
                'goal_time_seconds' => $request['goal_time_seconds'],
                'race_date' => $request['race_date'],
                'schedule' => $schedule,
            ],
        ]);
    }
}
