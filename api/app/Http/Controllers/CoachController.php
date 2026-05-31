<?php

namespace App\Http\Controllers;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Http\Requests\SendMessageRequest;
use App\Models\CoachProposal;
use App\Models\TrainingWeek;
use App\Services\AgentStreamingService;
use App\Services\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Laravel\Ai\Contracts\ConversationStore;
use Symfony\Component\HttpFoundation\StreamedResponse;

class CoachController extends Controller
{
    public function __construct(
        private ProposalService $proposalService,
        private AgentStreamingService $streamer,
    ) {}

    public function index(Request $request): JsonResponse
    {
        // Show plain coach chats AND schedule-week-scoped chats in the same
        // list (both run through RunCoachAgent). Workout chats stay hidden
        // because they're scoped to a different agent (WorkoutAgent) and
        // surface only in the per-day sheet.
        $conversations = DB::table('agent_conversations')
            ->where('user_id', $request->user()->id)
            ->whereNull('context')
            ->where(function ($q) {
                $q->whereNull('subject_type')
                    ->orWhere('subject_type', 'training_week');
            })
            ->orderByDesc('updated_at')
            ->get(['id', 'title', 'created_at', 'updated_at']);

        return response()->json(['data' => $conversations]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            // Only `training_week` is supported for now. The workout-chat
            // flow has its own controller / agent / endpoint, so we don't
            // accept `training_day` here.
            'subject_type' => ['sometimes', 'nullable', 'string', Rule::in(['training_week'])],
            'subject_id' => ['required_with:subject_type', 'integer'],
        ]);

        $userId = $request->user()->id;
        $title = $request->input('title', 'New Chat');
        $subjectType = $request->input('subject_type');
        $subjectId = $request->input('subject_id');

        if ($subjectType === 'training_week') {
            $owns = TrainingWeek::where('id', $subjectId)
                ->whereHas('goal', fn ($q) => $q->where('user_id', $userId))
                ->exists();
            abort_unless($owns, 403, 'Training week not found for this user.');

            // Direct DB insert mirrors WorkoutChatController — the SDK's
            // ConversationStore::storeConversation contract doesn't expose
            // subject binding, and we want the row created in one shot so
            // the agent's resolveTrainingWeekContext picks it up on the
            // first send.
            $conversationId = (string) Str::uuid();
            $now = now();
            DB::table('agent_conversations')->insert([
                'id' => $conversationId,
                'user_id' => $userId,
                'title' => $title,
                'context' => null,
                'subject_type' => 'training_week',
                'subject_id' => $subjectId,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            return response()->json([
                'data' => [
                    'id' => $conversationId,
                    'title' => $title,
                ],
            ], 201);
        }

        // Plain coach chat — let the SDK manage the row.
        $conversationId = app(ConversationStore::class)
            ->storeConversation($userId, $title);

        return response()->json([
            'data' => [
                'id' => $conversationId,
                'title' => $title,
            ],
        ], 201);
    }

    public function show(Request $request, string $conversationId): JsonResponse
    {
        $conversation = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->whereIn('role', ['user', 'assistant'])
            ->orderBy('created_at')
            ->get(['id', 'role', 'content', 'tool_results', 'created_at']);

        $proposals = CoachProposal::where('user_id', $request->user()->id)
            ->whereIn('agent_message_id', $messages->pluck('id'))
            ->get()
            ->keyBy('agent_message_id');

        $messagesWithProposals = $messages->map(function ($msg) use ($proposals) {
            $msg->proposal = $proposals->get($msg->id);
            $msg->tool_results = json_decode($msg->tool_results ?? '[]', true) ?: [];

            return $msg;
        });

        return response()->json([
            'data' => [
                'id' => $conversation->id,
                'title' => $conversation->title,
                // Surfaced so the Flutter chat screen can tell the onboarding
                // conversation apart (it hides the agent's priming first user
                // message there). Null for normal coach chats.
                'context' => $conversation->context,
                'messages' => $messagesWithProposals,
            ],
        ]);
    }

    public function destroy(Request $request, string $conversationId): JsonResponse
    {
        $userId = $request->user()->id;

        $conversation = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $userId)
            ->firstOrFail();

        DB::transaction(function () use ($conversation, $userId) {
            $messageIds = DB::table('agent_conversation_messages')
                ->where('conversation_id', $conversation->id)
                ->pluck('id');

            CoachProposal::where('user_id', $userId)
                ->whereIn('agent_message_id', $messageIds)
                ->delete();

            DB::table('agent_conversation_messages')
                ->where('conversation_id', $conversation->id)
                ->delete();

            DB::table('agent_conversations')
                ->where('id', $conversation->id)
                ->delete();
        });

        return response()->json(null, 204);
    }

    public function sendMessage(SendMessageRequest $request, string $conversationId): StreamedResponse
    {
        $user = $request->user();
        $content = $request->validated()['content'];

        $conversation = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $this->maybeAutoTitle($conversation, $content);

        // Single-line user-message log for chat debugging. Mirrors the
        // `[agent:tool]` / `[ai:usage]` pattern so the whole turn reads
        // top-to-bottom: user message → tool calls → token usage → reply.
        Log::info(sprintf(
            '[chat:user] cid=%s user_id=%d ctx=%s message=%s',
            $conversationId,
            $user->id,
            $conversation->context ?? 'null',
            json_encode($content, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        ));

        return response()->stream(function () use ($user, $conversationId, $content) {
            $agent = RunCoachAgent::make(user: $user)
                ->continue($conversationId, as: $user);

            $this->streamer->stream(
                $agent,
                $conversationId,
                $user,
                $content,
                logContext: 'coach',
            );
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache, no-transform',
            'X-Accel-Buffering' => 'no',
        ]);
    }

    public function acceptProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::where('user_id', $request->user()->id)
            ->find($proposalId);

        if (! $proposal) {
            Log::warning(sprintf(
                '[proposal:accept-stale] user_id=%d proposal_id=%d outcome=not_found',
                $request->user()->id, $proposalId,
            ));
            abort(404, 'Proposal not found.');
        }

        if ($proposal->status !== ProposalStatus::Pending) {
            $latest = CoachProposal::where('user_id', $request->user()->id)
                ->where('status', ProposalStatus::Pending)
                ->latest('id')
                ->first();
            Log::warning(sprintf(
                '[proposal:accept-stale] user_id=%d proposal_id=%d status=%s latest_pending=%s',
                $request->user()->id,
                $proposalId,
                $proposal->status->value,
                $latest?->id ?? 'none',
            ));
            abort(409, 'This proposal was replaced by a newer one. Pull to refresh the chat.');
        }

        $this->proposalService->apply($proposal, $request->user());

        return response()->json(['message' => 'Proposal accepted and applied']);
    }

    public function rejectProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::where('user_id', $request->user()->id)
            ->find($proposalId);

        if (! $proposal) {
            abort(404, 'Proposal not found.');
        }

        if ($proposal->status !== ProposalStatus::Pending) {
            // Idempotent reject: already-rejected proposals return 200 so
            // a stale-card tap doesn't surface a scary error toast.
            Log::info(sprintf(
                '[proposal:reject-stale] user_id=%d proposal_id=%d status=%s',
                $request->user()->id, $proposalId, $proposal->status->value,
            ));

            return response()->json(['message' => 'Proposal already inactive']);
        }

        $proposal->update(['status' => ProposalStatus::Rejected]);

        return response()->json(['message' => 'Proposal rejected']);
    }

    /**
     * When a user sends the first message into a freshly-created conversation
     * (still titled "New Chat" from the create endpoint), rename the
     * conversation using the first 5-6 words of their message so the list
     * view shows something meaningful.
     *
     * @param  object  $conversation  raw row from agent_conversations
     */
    private function maybeAutoTitle(object $conversation, string $content): void
    {
        $current = trim((string) ($conversation->title ?? ''));
        if ($current !== '' && mb_strtolower($current) !== 'new chat') {
            return;
        }

        $hasPriorUserMessage = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversation->id)
            ->where('role', 'user')
            ->exists();
        if ($hasPriorUserMessage) {
            return;
        }

        $title = $this->deriveTitleFromMessage($content);
        if ($title === '') {
            return;
        }

        DB::table('agent_conversations')
            ->where('id', $conversation->id)
            ->update(['title' => $title, 'updated_at' => now()]);
    }

    /**
     * Build a short conversation title (≤ 50 chars, ≤ 6 words) from a free-text
     * user message. Trims whitespace, capitalises the first letter, drops
     * trailing punctuation, appends an ellipsis when truncated.
     */
    private function deriveTitleFromMessage(string $content): string
    {
        $clean = trim(preg_replace('/\s+/', ' ', $content) ?? '');
        if ($clean === '') {
            return '';
        }

        $words = explode(' ', $clean);
        $picked = array_slice($words, 0, 6);
        $title = implode(' ', $picked);

        if (mb_strlen($title) > 50) {
            $title = rtrim(mb_substr($title, 0, 50));
            $title .= '…';
        } elseif (count($words) > 6) {
            $title .= '…';
        } else {
            $title = rtrim($title, ' .,!?;:—-');
        }

        return mb_strtoupper(mb_substr($title, 0, 1)).mb_substr($title, 1);
    }
}
