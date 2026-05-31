<?php

namespace App\Http\Controllers\Api;

use App\Enums\PlanEvaluationStatus;
use App\Enums\ProposalStatus;
use App\Http\Controllers\Controller;
use App\Models\PlanEvaluation;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Hard ceiling on items returned to the client. The inbox is meant for
     * a handful of action-required items — anything beyond this is almost
     * certainly a bug or runaway producer that we'd rather cap than ship.
     */
    private const MAX_INBOX_ITEMS = 50;

    public function __construct(private ProposalService $proposals) {}

    public function index(Request $request): JsonResponse
    {
        $notifications = UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('status', UserNotification::STATUS_PENDING)
            ->orderByDesc('id')
            ->limit(self::MAX_INBOX_ITEMS)
            ->get();

        return response()->json(['data' => $notifications]);
    }

    public function accept(Request $request, UserNotification $notification): JsonResponse
    {
        $user = $request->user();
        abort_unless($notification->user_id === $user->id, 403);
        abort_unless($notification->status === UserNotification::STATUS_PENDING, 422, 'Notification already handled.');

        match ($notification->type) {
            UserNotification::TYPE_PLAN_EVALUATION => $this->applyPlanEvaluation($user, $notification),
            default => abort(422, "Unknown notification type: {$notification->type}"),
        };

        $notification->update([
            'status' => UserNotification::STATUS_ACCEPTED,
            'acted_at' => now(),
        ]);

        return response()->json(['data' => $notification->fresh()]);
    }

    public function dismiss(Request $request, UserNotification $notification): JsonResponse
    {
        $user = $request->user();
        abort_unless($notification->user_id === $user->id, 403);
        abort_unless($notification->status === UserNotification::STATUS_PENDING, 422, 'Notification already handled.');

        if ($notification->type === UserNotification::TYPE_PLAN_EVALUATION) {
            PlanEvaluation::where('notification_id', $notification->id)
                ->update(['status' => PlanEvaluationStatus::Dismissed]);
        }

        $notification->update([
            'status' => UserNotification::STATUS_DISMISSED,
            'acted_at' => now(),
        ]);

        return response()->json(['data' => $notification->fresh()]);
    }

    /**
     * Accept a plan-evaluation notification. If the AI attached a proposal,
     * apply it via the standard ProposalService flow (same path as the
     * coach-chat ProposalCard). When the agent decided no change was needed
     * the row stays linked-but-proposal-less; accept just marks both rows
     * accepted.
     */
    private function applyPlanEvaluation(User $user, UserNotification $notification): void
    {
        $evaluation = PlanEvaluation::with('proposal')
            ->where('notification_id', $notification->id)
            ->where('user_id', $user->id)
            ->first();

        if ($evaluation === null) {
            return;
        }

        $proposal = $evaluation->proposal;
        if ($proposal !== null
            && $proposal->user_id === $user->id
            && $proposal->status === ProposalStatus::Pending) {
            $this->proposals->apply($proposal, $user);
        }

        $evaluation->update(['status' => PlanEvaluationStatus::Accepted]);
    }
}
