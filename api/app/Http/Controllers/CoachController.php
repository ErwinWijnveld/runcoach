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

class CoachController extends Controller
{
    public function __construct(
        private ProposalService $proposalService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $conversations = DB::table('agent_conversations')
            ->where('user_id', $request->user()->id)
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
            ->get(['id', 'role', 'content', 'created_at']);

        $proposals = CoachProposal::where('user_id', $request->user()->id)
            ->whereIn('agent_message_id', $messages->pluck('id'))
            ->get()
            ->keyBy('agent_message_id');

        $messagesWithProposals = $messages->map(function ($msg) use ($proposals) {
            $msg->proposal = $proposals->get($msg->id);

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

    public function sendMessage(SendMessageRequest $request, string $conversationId): JsonResponse
    {
        $user = $request->user();

        // Verify conversation belongs to user
        DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $agent = RunCoachAgent::make(user: $user);
        $response = $agent
            ->continue($conversationId, as: $user)
            ->prompt($request->validated()['content']);

        // Check for proposals in the SDK's stored tool results
        $proposal = $this->proposalService->detectProposalFromConversation(
            $user,
            $conversationId,
        );

        return response()->json([
            'data' => [
                'message' => [
                    'role' => 'assistant',
                    'content' => (string) $response,
                ],
                'proposal' => $proposal,
            ],
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
