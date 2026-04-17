<?php

namespace App\Http\Controllers;

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
}
