<?php

namespace App\Http\Controllers;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Http\Requests\SendMessageRequest;
use App\Models\CoachProposal;
use App\Services\AgentStreamingService;
use App\Services\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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
        $conversations = DB::table('agent_conversations')
            ->where('user_id', $request->user()->id)
            ->whereNull('context')
            ->whereNull('subject_type')
            ->orderByDesc('updated_at')
            ->get(['id', 'title', 'created_at', 'updated_at']);

        return response()->json(['data' => $conversations]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['title' => 'sometimes|string|max:255']);

        $title = $request->input('title', 'New Chat');

        // Just create the conversation record — no AI call needed
        $conversationId = app(ConversationStore::class)
            ->storeConversation($request->user()->id, $title);

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
            ->where('status', ProposalStatus::Pending)
            ->findOrFail($proposalId);

        $this->proposalService->apply($proposal, $request->user());

        return response()->json(['message' => 'Proposal accepted and applied']);
    }

    public function rejectProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::where('user_id', $request->user()->id)
            ->where('status', ProposalStatus::Pending)
            ->findOrFail($proposalId);

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
