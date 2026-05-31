<?php

namespace App\Http\Controllers\Api;

use App\Enums\GoalStatus;
use App\Http\Controllers\Controller;
use App\Models\Goal;
use App\Models\PlanEvaluation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanEvaluationController extends Controller
{
    /**
     * List evaluations for the user's active goal. The schedule UI calls
     * this once when the schedule loads so it can interleave evaluation
     * cards alongside the week's training days.
     */
    public function indexForActiveGoal(Request $request): JsonResponse
    {
        $user = $request->user();

        $goal = $user->goals()
            ->where('status', GoalStatus::Active)
            ->latest('id')
            ->first();

        if (! $goal) {
            return response()->json(['data' => []]);
        }

        $evaluations = PlanEvaluation::query()
            ->where('user_id', $user->id)
            ->where('goal_id', $goal->id)
            ->orderBy('scheduled_for')
            ->get();

        return response()->json(['data' => $evaluations]);
    }

    public function indexForGoal(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $evaluations = PlanEvaluation::query()
            ->where('goal_id', $goal->id)
            ->orderBy('scheduled_for')
            ->get();

        return response()->json(['data' => $evaluations]);
    }

    public function show(Request $request, PlanEvaluation $evaluation): JsonResponse
    {
        abort_unless($evaluation->user_id === $request->user()->id, 403);

        $evaluation->load(['proposal', 'notification']);

        return response()->json(['data' => $evaluation]);
    }
}
