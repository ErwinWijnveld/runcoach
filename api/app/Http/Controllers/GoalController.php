<?php

namespace App\Http\Controllers;

use App\Enums\GoalStatus;
use App\Http\Requests\StoreGoalRequest;
use App\Models\Goal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $goals = $request->user()->goals()
            ->orderByDesc('target_date')
            ->get();

        return response()->json(['data' => $goals]);
    }

    public function store(StoreGoalRequest $request): JsonResponse
    {
        $goal = $request->user()->goals()->create(
            $request->validated()
        );

        return response()->json(['data' => $goal], 201);
    }

    public function show(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        return response()->json([
            'data' => $goal,
            'weeks_until_target_date' => $goal->weeksUntilTargetDate(),
        ]);
    }

    public function update(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'goal_time_seconds' => ['sometimes', 'nullable', 'integer', 'min:60'],
            'target_date' => ['sometimes', 'nullable', 'date'],
        ]);

        $goal->update($validated);

        return response()->json(['data' => $goal->fresh()]);
    }

    public function destroy(Request $request, Goal $goal): JsonResponse
    {
        abort_unless($goal->user_id === $request->user()->id, 403);

        $goal->update(['status' => GoalStatus::Cancelled]);

        return response()->json(['message' => 'Goal cancelled']);
    }
}
