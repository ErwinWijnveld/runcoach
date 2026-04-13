<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetCurrentSchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get the user\'s active training schedule with all weeks, days, target paces/distances, and compliance results for completed sessions.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_id' => $schema->integer()->required()->nullable()->description('Specific race ID. Omit or pass null to get the active race.'),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $request['race_id']
            ? $this->user->races()->find($request['race_id'])
            : $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found.']);
        }

        $weeks = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        $data = [
            'race' => [
                'name' => $race->name,
                'distance' => $race->distance->value,
                'race_date' => $race->race_date->toDateString(),
                'weeks_until_race' => $race->weeksUntilRace(),
            ],
            'weeks' => $weeks->map(fn ($week) => [
                'week_number' => $week->week_number,
                'starts_at' => $week->starts_at->toDateString(),
                'total_km' => $week->total_km,
                'focus' => $week->focus,
                'days' => $week->trainingDays->map(fn ($day) => [
                    'id' => $day->id,
                    'date' => $day->date->toDateString(),
                    'type' => $day->type->value,
                    'title' => $day->title,
                    'target_km' => $day->target_km,
                    'target_pace_seconds_per_km' => $day->target_pace_seconds_per_km,
                    'completed' => $day->result !== null,
                    'compliance_score' => $day->result?->compliance_score,
                ])->toArray(),
            ])->toArray(),
        ];

        return json_encode($data);
    }
}
