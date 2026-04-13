<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRaceInfo implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get details about the user\'s active or specific race: name, distance, date, goal time, weeks remaining, completion rate, and readiness assessment.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_id' => $schema->integer()->required()->nullable()->description('Specific race ID, or null for active race.'),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $request['race_id']
            ? $this->user->races()->find($request['race_id'])
            : $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found. The runner has not set up a race goal yet.']);
        }

        $totalDays = $race->trainingWeeks()->withCount('trainingDays')->get()->sum('training_days_count');
        $completedResults = TrainingResult::whereHas('trainingDay.trainingWeek', fn ($q) => $q->where('race_id', $race->id))->get();
        $completionRate = $totalDays > 0 ? round($completedResults->count() / $totalDays * 100, 1) : 0;

        return json_encode([
            'name' => $race->name,
            'distance' => $race->distance->value,
            'goal_time_seconds' => $race->goal_time_seconds,
            'race_date' => $race->race_date->toDateString(),
            'weeks_until_race' => $race->weeksUntilRace(),
            'status' => $race->status->value,
            'completion_rate_percent' => $completionRate,
            'sessions_completed' => $completedResults->count(),
            'sessions_planned' => $totalDays,
            'avg_compliance' => $completedResults->count() > 0 ? round($completedResults->avg('compliance_score'), 1) : null,
        ]);
    }
}
