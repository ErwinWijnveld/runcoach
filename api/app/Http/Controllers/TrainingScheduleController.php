<?php

namespace App\Http\Controllers;

use App\Models\Race;
use App\Models\TrainingDay;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrainingScheduleController extends Controller
{
    public function schedule(Request $request, Race $race): JsonResponse
    {
        abort_unless($race->user_id === $request->user()->id, 403);

        $weeks = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        return response()->json(['data' => $weeks]);
    }

    public function currentWeek(Request $request, Race $race): JsonResponse
    {
        abort_unless($race->user_id === $request->user()->id, 403);

        $week = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        return response()->json(['data' => $week]);
    }

    public function showDay(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.race', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->with('trainingWeek', 'result')->findOrFail($dayId);

        return response()->json(['data' => $day]);
    }

    public function dayResult(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.race', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->findOrFail($dayId);

        $result = $day->result?->load('stravaActivity');

        return response()->json(['data' => $result]);
    }
}
