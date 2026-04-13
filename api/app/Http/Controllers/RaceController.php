<?php

namespace App\Http\Controllers;

use App\Enums\RaceStatus;
use App\Http\Requests\StoreRaceRequest;
use App\Models\Race;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RaceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $races = $request->user()->races()
            ->orderByDesc('race_date')
            ->get();

        return response()->json(['data' => $races]);
    }

    public function store(StoreRaceRequest $request): JsonResponse
    {
        $race = $request->user()->races()->create(
            $request->validated()
        );

        return response()->json(['data' => $race], 201);
    }

    public function show(Request $request, Race $race): JsonResponse
    {
        abort_unless($race->user_id === $request->user()->id, 403);

        return response()->json([
            'data' => $race,
            'weeks_until_race' => $race->weeksUntilRace(),
        ]);
    }

    public function update(Request $request, Race $race): JsonResponse
    {
        abort_unless($race->user_id === $request->user()->id, 403);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'goal_time_seconds' => ['sometimes', 'nullable', 'integer', 'min:300'],
            'race_date' => ['sometimes', 'date', 'after:today'],
        ]);

        $race->update($validated);

        return response()->json(['data' => $race->fresh()]);
    }

    public function destroy(Request $request, Race $race): JsonResponse
    {
        abort_unless($race->user_id === $request->user()->id, 403);

        $race->update(['status' => RaceStatus::Cancelled]);

        return response()->json(['message' => 'Race cancelled']);
    }
}
