<?php

namespace App\Http\Controllers;

use App\Jobs\AnalyzeRunningProfileJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    public function reply(Request $request, string $conversationId): JsonResponse
    {
        $validated = $request->validate([
            'text' => 'required|string',
            'chip_value' => 'nullable|string',
        ]);

        $conversation = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $request->user()->id)
            ->where('context', 'onboarding')
            ->first();

        if (! $conversation) {
            abort(404);
        }

        $now = now();
        $chipValue = $validated['chip_value'] ?? null;

        DB::table('agent_conversation_messages')->insert([
            'id' => (string) Str::uuid(),
            'conversation_id' => $conversationId,
            'user_id' => $request->user()->id,
            'agent' => 'RunCoachAgent',
            'role' => 'user',
            'content' => $validated['text'],
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => json_encode($chipValue ? ['chip_value' => $chipValue] : []),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $meta = json_decode($conversation->meta, true) ?? [];
        $step = $meta['onboarding_step'] ?? 'awaiting_branch';

        $appended = $this->advance($conversationId, $meta, $step, $validated['text'], $chipValue);

        $decoded = collect($appended)->map(function ($m) {
            $m->meta = json_decode($m->meta, true) ?? [];

            return $m;
        });

        return response()->json(['messages' => $decoded]);
    }

    /**
     * Drive the state machine forward by one user reply.
     * Returns the newly appended assistant message rows (stdClass).
     *
     * @param  array<string, mixed>  $meta  current conversation meta (decoded)
     * @return list<\stdClass>
     */
    private function advance(string $conversationId, array $meta, string $step, string $text, ?string $chipValue): array
    {
        $appended = [];

        if ($step === 'awaiting_branch') {
            $branch = $chipValue ?? $this->resolveChip($text, ['race', 'general_fitness', 'pr_attempt', 'skip']);

            if ($branch === 'race') {
                $appended[] = $this->appendAssistant($conversationId, 'text', $this->racePromptCopy());
                $this->setStep($conversationId, $meta, 'awaiting_race_details');
            }
            // Other branches handled in subsequent tasks
        }

        return $appended;
    }

    private function racePromptCopy(): string
    {
        return "Alright, let's get you going!\n\n"
            ."To create the plan, I need 3 things:\n"
            ."  1. Race name\n"
            ."  2. Race date\n"
            ."  3. Goal time, if you have one\n\n"
            ."Optional but helpful:\n"
            ."  • Race distance if it's not obvious from the name\n"
            ."  • How many days/week you want to run\n"
            ."  • Any injuries or days you can't train\n\n"
            .'Send me something like: "City 10K, 12th of september 2025, goal 55:00, 4 days/week"';
    }

    /**
     * Stub: lowercase substring match. Full LLM classifier in later task.
     */
    private function resolveChip(string $text, array $expected): ?string
    {
        $normalized = strtolower(trim($text));
        foreach ($expected as $value) {
            if (str_contains($normalized, $value)) {
                return $value;
            }
        }

        return null;
    }

    private function appendAssistant(string $conversationId, string $type, string $content = '', array $payload = []): \stdClass
    {
        $id = (string) Str::uuid();
        $now = now();
        $metaJson = json_encode([
            'message_type' => $type,
            'message_payload' => $payload,
        ]);

        DB::table('agent_conversation_messages')->insert([
            'id' => $id,
            'conversation_id' => $conversationId,
            'user_id' => DB::table('agent_conversations')->where('id', $conversationId)->value('user_id'),
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => $content,
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '[]',
            'meta' => $metaJson,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return DB::table('agent_conversation_messages')->where('id', $id)->first();
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    private function setStep(string $conversationId, array &$meta, string $step): void
    {
        $meta['onboarding_step'] = $step;
        DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->update([
                'meta' => json_encode($meta),
                'updated_at' => now(),
            ]);
    }

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
