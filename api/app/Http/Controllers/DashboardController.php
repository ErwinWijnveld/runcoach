<?php

namespace App\Http\Controllers;

use App\Enums\GoalStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $goal = $user->goals()->where('status', GoalStatus::Active)->latest()->first();

        if (! $goal) {
            return response()->json([
                'weekly_summary' => null,
                'next_training' => null,
                'active_goal' => null,
                'coach_insight' => null,
            ]);
        }

        $currentWeek = $goal->trainingWeeks()
            ->with('trainingDays.result')
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        $weeklySummary = null;
        $nextTraining = null;
        $coachInsight = null;

        if ($currentWeek) {
            $completedResults = $currentWeek->trainingDays
                ->filter(fn ($day) => $day->result !== null);

            $totalKmCompleted = $completedResults->sum(fn ($day) => $day->result->actual_km);
            $avgCompliance = $completedResults->count() > 0
                ? round($completedResults->avg(fn ($day) => $day->result->compliance_score), 1)
                : null;

            $weeklySummary = [
                'total_km_planned' => $currentWeek->total_km,
                'total_km_completed' => $totalKmCompleted,
                'sessions_completed' => $completedResults->count(),
                'sessions_total' => $currentWeek->trainingDays->count(),
                'compliance_avg' => $avgCompliance,
            ];

            $nextTraining = $currentWeek->trainingDays
                ->where('date', '>=', now()->toDateString())
                ->whereNull('result')
                ->sortBy('date')
                ->first();

            $coachInsight = $currentWeek->coach_notes;
        }

        return response()->json([
            'weekly_summary' => $weeklySummary,
            'next_training' => $nextTraining,
            'active_goal' => [
                'id' => $goal->id,
                'type' => $goal->type?->value,
                'name' => $goal->name,
                'distance' => $goal->distance?->value,
                'target_date' => $goal->target_date?->toDateString(),
                'weeks_until_target_date' => $goal->weeksUntilTargetDate(),
            ],
            'coach_insight' => $coachInsight,
        ]);
    }
}
