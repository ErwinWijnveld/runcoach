<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateProfileRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->user()->only([
                'id', 'name', 'email', 'strava_athlete_id', 'strava_profile_url',
                'coach_style', 'has_completed_onboarding',
            ]),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $request->user()->fresh()->only([
                'id', 'name', 'email', 'strava_athlete_id', 'strava_profile_url',
                'coach_style', 'has_completed_onboarding',
            ]),
        ]);
    }

    public function destroy(Request $request): Response
    {
        /** @var User $user */
        $user = $request->user();

        DB::transaction(function () use ($user) {
            // Sanctum tokens: polymorphic, no FK cascade from users.
            $user->tokens()->delete();

            // Laravel AI SDK tables: `user_id` is a nullable bigint with no FK
            // constraint, so user deletion does not cascade. Delete explicitly.
            $conversationIds = DB::table('agent_conversations')
                ->where('user_id', $user->id)
                ->pluck('id');

            if ($conversationIds->isNotEmpty()) {
                DB::table('agent_conversation_messages')
                    ->whereIn('conversation_id', $conversationIds)
                    ->delete();

                DB::table('agent_conversations')
                    ->whereIn('id', $conversationIds)
                    ->delete();
            }

            $user->delete();
        });

        return response()->noContent();
    }
}
