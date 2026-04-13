<?php

namespace App\Http\Controllers;

use App\Http\Requests\OnboardingRequest;
use App\Http\Requests\UpdateProfileRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->user()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $request->user()->fresh()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }

    public function onboarding(OnboardingRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $request->user()->fresh()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }
}
