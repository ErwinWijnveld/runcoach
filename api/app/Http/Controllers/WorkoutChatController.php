<?php

namespace App\Http\Controllers;

use App\Ai\Agents\WorkoutAgent;
use App\Http\Requests\SendMessageRequest;
use App\Models\TrainingDay;
use App\Services\AgentStreamingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Per-training-day chat. One conversation per (user, training_day),
 * resolved-or-created lazily on the first sendMessage. Hidden from the
 * main coach chat list because rows have `subject_type='training_day'`.
 */
class WorkoutChatController extends Controller
{
    public function __construct(
        private AgentStreamingService $streamer,
    ) {}

    public function show(Request $request, int $trainingDayId): JsonResponse
    {
        $user = $request->user();
        $this->resolveDay($user->id, $trainingDayId);

        $conversation = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('subject_type', 'training_day')
            ->where('subject_id', $trainingDayId)
            ->first(['id', 'title', 'created_at', 'updated_at']);

        if ($conversation === null) {
            return response()->json(['data' => null]);
        }

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversation->id)
            ->whereIn('role', ['user', 'assistant'])
            ->orderBy('created_at')
            ->get(['id', 'role', 'content', 'tool_results', 'created_at']);

        $messagesNormalized = $messages->map(function ($msg) {
            $msg->tool_results = json_decode($msg->tool_results ?? '[]', true) ?: [];

            return $msg;
        });

        return response()->json([
            'data' => [
                'id' => $conversation->id,
                'title' => $conversation->title,
                'training_day_id' => $trainingDayId,
                'messages' => $messagesNormalized,
            ],
        ]);
    }

    public function sendMessage(SendMessageRequest $request, int $trainingDayId): StreamedResponse
    {
        $user = $request->user();
        $content = $request->validated()['content'];

        $this->resolveDay($user->id, $trainingDayId);

        $conversationId = $this->resolveOrCreateConversation($user->id, $trainingDayId);

        return response()->stream(function () use ($user, $conversationId, $content) {
            $agent = WorkoutAgent::make(user: $user)
                ->continue($conversationId, as: $user);

            $this->streamer->stream(
                $agent,
                $conversationId,
                $user,
                $content,
                logContext: 'workout',
            );
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache, no-transform',
            'X-Accel-Buffering' => 'no',
        ]);
    }

    /**
     * Confirm the day belongs to the authenticated user. Returns the day
     * for callers that need it (we don't, but the lookup is the auth check).
     */
    private function resolveDay(int $userId, int $trainingDayId): TrainingDay
    {
        return TrainingDay::whereHas('trainingWeek.goal', function ($query) use ($userId) {
            $query->where('user_id', $userId);
        })->findOrFail($trainingDayId);
    }

    private function resolveOrCreateConversation(int $userId, int $trainingDayId): string
    {
        $existing = DB::table('agent_conversations')
            ->where('user_id', $userId)
            ->where('subject_type', 'training_day')
            ->where('subject_id', $trainingDayId)
            ->value('id');

        if ($existing !== null) {
            return (string) $existing;
        }

        $id = (string) Str::uuid();
        $now = now();
        DB::table('agent_conversations')->insert([
            'id' => $id,
            'user_id' => $userId,
            'title' => 'Workout chat',
            'context' => null,
            'subject_type' => 'training_day',
            'subject_id' => $trainingDayId,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $id;
    }
}
