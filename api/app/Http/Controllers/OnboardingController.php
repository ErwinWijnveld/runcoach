<?php

namespace App\Http\Controllers;

use App\Jobs\AnalyzeRunningProfileJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();

        $existing = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();

        if ($existing === null) {
            $conversationId = (string) Str::uuid();
            $now = now();

            DB::table('agent_conversations')->insert([
                'id' => $conversationId,
                'user_id' => $user->id,
                'title' => 'Onboarding',
                'context' => 'onboarding',
                'meta' => json_encode(['onboarding_step' => 'pending_analysis']),
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('agent_conversation_messages')->insert([
                'id' => (string) Str::uuid(),
                'conversation_id' => $conversationId,
                'user_id' => $user->id,
                'agent' => 'App\Ai\Agents\RunCoachAgent',
                'role' => 'assistant',
                'content' => '',
                'attachments' => '[]',
                'tool_calls' => '[]',
                'tool_results' => '[]',
                'usage' => '[]',
                'meta' => json_encode([
                    'message_type' => 'loading_card',
                    'message_payload' => ['label' => 'Analysing Strava Data'],
                ]),
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            AnalyzeRunningProfileJob::dispatch($conversationId, $user->id);
        } else {
            $conversationId = $existing->id;
        }

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->orderBy('created_at')
            ->get()
            ->map(function ($msg) {
                $msg->meta = json_decode($msg->meta, true) ?? [];

                return $msg;
            });

        return response()->json([
            'conversation_id' => $conversationId,
            'messages' => $messages,
        ]);
    }
}
