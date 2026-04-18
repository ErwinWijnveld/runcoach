<?php

namespace App\Http\Controllers;

use App\Http\Requests\GeneratePlanRequest;
use App\Services\OnboardingPlanGeneratorService;
use App\Services\RunningProfileService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    /**
     * Ensure an onboarding conversation exists for the user. Returns its id.
     * Idempotent: returns the existing onboarding conversation if one is open.
     *
     * The frontend then mounts CoachChatView pointed at this conversation and
     * sends its first message via the regular /coach/chat endpoint. The agent,
     * reading `context='onboarding'`, follows the onboarding script.
     *
     * @deprecated Replaced by the form-based onboarding flow
     *             (GET /onboarding/profile + POST /onboarding/generate-plan).
     *             Kept temporarily for backwards compatibility with older app builds.
     */
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();

        $existing = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();

        if ($existing !== null) {
            return response()->json(['conversation_id' => $existing->id]);
        }

        $conversationId = (string) Str::uuid();
        $now = now();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['conversation_id' => $conversationId]);
    }

    /**
     * Returns the user's running profile for the onboarding overview screen.
     * While Strava sync is still in flight, returns 202 with `{status:'syncing'}`.
     */
    public function profile(Request $request, RunningProfileService $profiles): JsonResponse
    {
        $profile = $profiles->getOrAnalyze($request->user());

        if ($profile === null) {
            return response()->json(['status' => 'syncing'], 202);
        }

        return response()->json([
            'status' => 'ready',
            'analyzed_at' => $profile->analyzed_at,
            'data_start_date' => $profile->data_start_date,
            'data_end_date' => $profile->data_end_date,
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }

    /**
     * Generate a training plan from the onboarding form payload.
     * Returns the IDs needed to show the plan inside the coach chat.
     */
    public function generatePlan(
        GeneratePlanRequest $request,
        OnboardingPlanGeneratorService $generator,
    ): JsonResponse {
        $result = $generator->generate($request->user(), $request->validated());

        return response()->json($result);
    }
}
