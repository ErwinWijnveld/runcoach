<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetComplianceReport implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get a detailed compliance report showing how well the runner has been following their training plan: per-session scores, averages, trends over time.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'period' => $schema->string()->enum(['week', 'month', 'all'])->description('Time period for the report')->required(),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found.']);
        }

        $query = TrainingResult::whereHas('trainingDay.trainingWeek', fn ($q) => $q->where('race_id', $race->id))
            ->with('trainingDay');

        $period = $request['period'] ?? 'all';
        if ($period === 'week') {
            $query->where('matched_at', '>=', now()->startOfWeek());
        } elseif ($period === 'month') {
            $query->where('matched_at', '>=', now()->subMonth());
        }

        $results = $query->orderByDesc('matched_at')->get();

        if ($results->isEmpty()) {
            return json_encode(['message' => 'No completed training sessions found for this period.']);
        }

        $sessions = $results->map(fn ($r) => [
            'date' => $r->trainingDay->date->toDateString(),
            'title' => $r->trainingDay->title,
            'type' => $r->trainingDay->type->value,
            'compliance_score' => $r->compliance_score,
            'pace_score' => $r->pace_score,
            'distance_score' => $r->distance_score,
            'actual_km' => $r->actual_km,
        ])->toArray();

        return json_encode([
            'period' => $period,
            'total_sessions' => $results->count(),
            'avg_compliance_score' => round($results->avg('compliance_score'), 1),
            'avg_pace_score' => round($results->avg('pace_score'), 1),
            'avg_distance_score' => round($results->avg('distance_score'), 1),
            'best_score' => $results->max('compliance_score'),
            'lowest_score' => $results->min('compliance_score'),
            'sessions' => $sessions,
        ]);
    }
}
