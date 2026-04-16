<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRunningProfile implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Get a fast snapshot of the user's 12-month running profile: weekly averages, typical pace, consistency score, volume trends, and a narrative summary.

        USE THIS for queries like:
        - "What's my running profile?"
        - "How fit am I?"
        - "What's my typical weekly mileage?"
        - "Give me an overview of my training history"
        - Assessing current fitness before building a training plan

        DO NOT use for date-range queries like "how was last April?" or "compare this month vs last" — use search_strava_activities for those.
        This is a fast cached lookup (no Strava API call). If no profile is cached yet, the response will indicate that.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [];
    }

    public function handle(Request $request): string
    {
        $profile = $this->user->runningProfile;

        if (! $profile) {
            return json_encode([
                'message' => 'No running profile cached yet. The runner has not completed the onboarding analysis, or the profile has not been generated.',
            ]);
        }

        return json_encode([
            'analyzed_at' => $profile->analyzed_at->toDateTimeString(),
            'data_start_date' => $profile->data_start_date?->toDateString(),
            'data_end_date' => $profile->data_end_date?->toDateString(),
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }
}
