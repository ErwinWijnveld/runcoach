<?php

namespace App\Http\Controllers;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Http\Requests\SendMessageRequest;
use App\Models\CoachProposal;
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
    ) {}

    public function index(Request $request): JsonResponse
    {
        $conversations = DB::table('agent_conversations')
            ->where('user_id', $request->user()->id)
            ->whereNull('context')
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

    public function sendMessage(SendMessageRequest $request, string $conversationId): StreamedResponse
    {
        $user = $request->user();
        $content = $request->validated()['content'];

        DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        return response()->stream(function () use ($user, $conversationId, $content) {
            ignore_user_abort(true);
            set_time_limit(0);

            $stream = RunCoachAgent::make(user: $user)
                ->continue($conversationId, as: $user)
                ->stream($content);

            foreach ($stream as $event) {
                $payload = $event->toVercelProtocolArray();
                if (! empty($payload)) {
                    echo 'data: '.json_encode($payload)."\n\n";
                    ob_flush();
                    flush();
                }
            }

            $proposal = $this->proposalService
                ->detectProposalFromConversation($user, $conversationId);

            if ($proposal) {
                echo 'data: '.json_encode([
                    'type' => 'data-proposal',
                    'data' => $proposal->toArray(),
                ])."\n\n";
                ob_flush();
                flush();
            }

            echo "data: [DONE]\n\n";
            ob_flush();
            flush();
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
}
