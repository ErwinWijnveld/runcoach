<?php

namespace App\Http\Controllers;

use App\Jobs\AnalyzeRunningProfileJob;
use App\Jobs\RunOnboardingPlanAgentJob;
use App\Models\User;
use App\Services\ChipClassifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    public function __construct(
        private readonly ChipClassifier $chipClassifier,
    ) {}

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

            if ($branch === null) {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "I didn't quite catch that — which of these matches?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => 'Race coming up!', 'value' => 'race'],
                        ['label' => 'General fitness', 'value' => 'general_fitness'],
                        ['label' => 'Get faster', 'value' => 'pr_attempt'],
                        ['label' => 'Not sure yet', 'value' => 'skip'],
                    ],
                ], $base->copy()->addSecond());

                return $appended;
            }

            $meta['path'] = $branch;

            if ($branch === 'race') {
                $appended[] = $this->appendAssistant($conversationId, 'text', $this->racePromptCopy());
                $this->setStep($conversationId, $meta, 'awaiting_race_details');
            }

            if ($branch === 'general_fitness') {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "Nice — let's keep you moving. How many days per week can you run?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => '2 days', 'value' => '2'],
                        ['label' => '3 days', 'value' => '3'],
                        ['label' => '4 days', 'value' => '4'],
                        ['label' => '5 days', 'value' => '5'],
                        ['label' => '6 days', 'value' => '6'],
                    ],
                ], $base->copy()->addSecond());
                $this->setStep($conversationId, $meta, 'awaiting_fitness_days');
            }

            if ($branch === 'pr_attempt') {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', 'What distance do you want to get faster at?', [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => '5k', 'value' => '5k'],
                        ['label' => '10k', 'value' => '10k'],
                        ['label' => 'Half marathon', 'value' => 'half_marathon'],
                        ['label' => 'Marathon', 'value' => 'marathon'],
                        ['label' => 'Custom', 'value' => 'custom'],
                    ],
                ], $base->copy()->addSecond());
                $this->setStep($conversationId, $meta, 'awaiting_faster_distance');
            }

            if ($branch === 'skip') {
                $userId = DB::table('agent_conversations')->where('id', $conversationId)->value('user_id');
                $user = User::find($userId);
                $user->has_completed_onboarding = true;
                $user->save();

                $appended[] = $this->appendAssistant($conversationId, 'text',
                    "No stress. Your running history is in and I've got it from here. "
                    .'Whenever you want to set a goal, just ask me — I\'ll be on the coach tab.'
                );
                $this->setStep($conversationId, $meta, 'abandoned');
            }
        }

        if ($step === 'awaiting_race_details') {
            $meta['race_details_raw'] = $text;

            $base = now();
            $appended[] = $this->appendAssistant($conversationId, 'text', 'One last thing — how do you want me to coach you?', [], $base->copy());
            $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                'chips' => [
                    ['label' => 'Strict — hold me to it', 'value' => 'strict'],
                    ['label' => 'Balanced', 'value' => 'balanced'],
                    ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
                ],
            ], $base->copy()->addSecond());
            $this->setStep($conversationId, $meta, 'awaiting_coach_style');
        }

        if ($step === 'awaiting_fitness_days') {
            $resolved = $chipValue ?? $this->resolveChip($text, ['2', '3', '4', '5', '6']);
            $days = (int) $resolved;
            if ($days < 2 || $days > 6) {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "I didn't quite catch that — how many days per week can you run?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => '2 days', 'value' => '2'],
                        ['label' => '3 days', 'value' => '3'],
                        ['label' => '4 days', 'value' => '4'],
                        ['label' => '5 days', 'value' => '5'],
                        ['label' => '6 days', 'value' => '6'],
                    ],
                ], $base->copy()->addSecond());

                return $appended;
            }

            $meta['days_per_week'] = $days;
            $base = now();
            $appended[] = $this->appendAssistant($conversationId, 'text', 'Got it. One last thing — how do you want me to coach you?', [], $base->copy());
            $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                'chips' => [
                    ['label' => 'Strict — hold me to it', 'value' => 'strict'],
                    ['label' => 'Balanced', 'value' => 'balanced'],
                    ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
                ],
            ], $base->copy()->addSecond());
            $this->setStep($conversationId, $meta, 'awaiting_coach_style');
        }

        if ($step === 'awaiting_faster_distance') {
            $distance = $chipValue ?? $this->resolveChip($text, ['5k', '10k', 'half_marathon', 'marathon', 'custom']);
            if ($distance === null) {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "I didn't quite catch that — what distance do you want to get faster at?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => '5k', 'value' => '5k'],
                        ['label' => '10k', 'value' => '10k'],
                        ['label' => 'Half marathon', 'value' => 'half_marathon'],
                        ['label' => 'Marathon', 'value' => 'marathon'],
                        ['label' => 'Custom', 'value' => 'custom'],
                    ],
                ], $base->copy()->addSecond());

                return $appended;
            }

            $meta['distance'] = $distance;

            $appended[] = $this->appendAssistant($conversationId, 'text', 'What\'s your current PR and target? e.g. "currently 22:30, target 20:00"');
            $this->setStep($conversationId, $meta, 'awaiting_faster_pr_target');
        }

        if ($step === 'awaiting_faster_pr_target') {
            $meta['pr_target_raw'] = $text;
            $base = now();
            $appended[] = $this->appendAssistant($conversationId, 'text', 'How many days per week?', [], $base->copy());
            $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                'chips' => [
                    ['label' => '2 days', 'value' => '2'],
                    ['label' => '3 days', 'value' => '3'],
                    ['label' => '4 days', 'value' => '4'],
                    ['label' => '5 days', 'value' => '5'],
                    ['label' => '6 days', 'value' => '6'],
                ],
            ], $base->copy()->addSecond());
            $this->setStep($conversationId, $meta, 'awaiting_faster_days');
        }

        if ($step === 'awaiting_faster_days') {
            $resolved = $chipValue ?? $this->resolveChip($text, ['2', '3', '4', '5', '6']);
            $days = (int) $resolved;
            if ($days < 2 || $days > 6) {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "I didn't quite catch that — how many days per week?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => '2 days', 'value' => '2'],
                        ['label' => '3 days', 'value' => '3'],
                        ['label' => '4 days', 'value' => '4'],
                        ['label' => '5 days', 'value' => '5'],
                        ['label' => '6 days', 'value' => '6'],
                    ],
                ], $base->copy()->addSecond());

                return $appended;
            }

            $meta['days_per_week'] = $days;
            $base = now();
            $appended[] = $this->appendAssistant($conversationId, 'text', 'One last thing — how do you want me to coach you?', [], $base->copy());
            $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                'chips' => [
                    ['label' => 'Strict — hold me to it', 'value' => 'strict'],
                    ['label' => 'Balanced', 'value' => 'balanced'],
                    ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
                ],
            ], $base->copy()->addSecond());
            $this->setStep($conversationId, $meta, 'awaiting_coach_style');
        }

        if ($step === 'awaiting_coach_style') {
            $coachStyle = $chipValue ?? $this->resolveChip($text, ['strict', 'balanced', 'flexible']);
            if ($coachStyle === null) {
                $base = now();
                $appended[] = $this->appendAssistant($conversationId, 'text', "I didn't quite catch that — how do you want me to coach you?", [], $base->copy());
                $appended[] = $this->appendAssistant($conversationId, 'chip_suggestions', '', [
                    'chips' => [
                        ['label' => 'Strict — hold me to it', 'value' => 'strict'],
                        ['label' => 'Balanced', 'value' => 'balanced'],
                        ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
                    ],
                ], $base->copy()->addSecond());

                return $appended;
            }

            $userId = DB::table('agent_conversations')->where('id', $conversationId)->value('user_id');
            $user = User::find($userId);
            $user->coach_style = $coachStyle;
            $user->save();

            $meta['coach_style'] = $coachStyle;

            $appended[] = $this->appendAssistant($conversationId, 'loading_card', '', [
                'label' => 'Working on your plan',
            ]);
            $this->setStep($conversationId, $meta, 'plan_generating');

            RunOnboardingPlanAgentJob::dispatch($conversationId, $userId);
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

    private function resolveChip(string $text, array $expectedValues): ?string
    {
        $normalized = strtolower(trim($text));

        foreach ($expectedValues as $value) {
            if ($normalized === strtolower($value) || str_contains($normalized, strtolower($value))) {
                return $value;
            }
        }

        $chips = array_map(fn ($v) => ['label' => $v, 'value' => $v], $expectedValues);

        return $this->chipClassifier->classify($text, $chips);
    }

    private function appendAssistant(string $conversationId, string $type, string $content = '', array $payload = [], ?Carbon $at = null): \stdClass
    {
        $id = (string) Str::uuid();
        $now = $at ?? now();
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
