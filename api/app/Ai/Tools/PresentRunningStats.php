<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class PresentRunningStats implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'TXT'
        Render a stats card in the chat for the user. Use this AS THE FIRST THING in an onboarding conversation, right after silently loading the profile, to show the user their 12-month snapshot. The UI will render a 2x2 grid of tiles with the supplied metrics. After calling this tool, follow up with a short warm narrative line and move on to asking what they're training for.

        DO NOT use this outside onboarding.
        TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'weekly_avg_km' => $schema->number()
                ->description('Weekly average kilometers over the last 12 months')
                ->required(),
            'weekly_avg_runs' => $schema->integer()
                ->description('Weekly average run count over the last 12 months')
                ->required(),
            'avg_pace_seconds_per_km' => $schema->integer()
                ->description('Average pace, seconds per km')
                ->required(),
            'session_avg_duration_seconds' => $schema->integer()
                ->description('Average run duration, seconds')
                ->required(),
        ];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'display' => 'stats_card',
            'metrics' => [
                'weekly_avg_km' => $request['weekly_avg_km'],
                'weekly_avg_runs' => $request['weekly_avg_runs'],
                'avg_pace_seconds_per_km' => $request['avg_pace_seconds_per_km'],
                'session_avg_duration_seconds' => $request['session_avg_duration_seconds'],
            ],
        ]);
    }
}
