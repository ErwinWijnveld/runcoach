<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRunningProfile implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Get the user's 12-month running profile (weekly averages, pace, consistency, narrative). Fast cached lookup. If no cache exists (first onboarding call), this triggers a fresh Strava fetch + analysis — takes 5–15 seconds but happens inline. Always returns a profile.

        USE THIS for queries like:
        - "What's my running profile?"
        - "How fit am I?"
        - "What's my typical weekly mileage?"
        - "Give me an overview of my training history"
        - Assessing current fitness before building a training plan

        DO NOT use for date-range queries like "how was last April?" or "compare this month vs last" — use search_strava_activities for those.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [];
    }

    public function handle(Request $request): string
    {
        $profile = UserRunningProfile::where('user_id', $this->user->id)->first();

        if (! $profile) {
            $profile = app(RunningProfileService::class)->analyze($this->user);
        }

        return json_encode([
            'analyzed_at' => optional($profile->analyzed_at)->toIso8601String(),
            'data_start_date' => $profile->data_start_date?->toDateString(),
            'data_end_date' => $profile->data_end_date?->toDateString(),
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }
}
