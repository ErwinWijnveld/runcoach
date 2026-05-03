<?php

namespace App\Http\Controllers\Api;

use App\Enums\GoalStatus;
use App\Http\Controllers\Controller;
use App\Models\TrainingDay;
use App\Models\User;
use App\Models\UserNotification;
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
            UserNotification::TYPE_PACE_ADJUSTMENT => $this->applyPaceAdjustment($user, $notification),
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
        abort_unless($notification->user_id === $request->user()->id, 403);
        abort_unless($notification->status === UserNotification::STATUS_PENDING, 422, 'Notification already handled.');

        $notification->update([
            'status' => UserNotification::STATUS_DISMISSED,
            'acted_at' => now(),
        ]);

        return response()->json(['data' => $notification->fresh()]);
    }

    /**
     * Walk every upcoming training day of the same type (whole active
     * plan, from today onward) and shift its target pace by the stored
     * factor. Race day is sacred — its pace IS the user's goal — so we
     * leave it untouched.
     */
    private function applyPaceAdjustment(User $user, UserNotification $notification): void
    {
        $factor = (float) ($notification->action_data['pace_factor'] ?? 1.0);
        $type = (string) ($notification->action_data['training_type'] ?? '');
        if ($factor === 1.0 || $type === '') {
            return;
        }

        $today = now()->startOfDay();

        TrainingDay::query()
            ->whereHas('trainingWeek.goal', fn ($q) => $q
                ->where('user_id', $user->id)
                ->where('status', GoalStatus::Active)
            )
            ->with('trainingWeek.goal')
            ->where('type', $type)
            ->where('date', '>=', $today)
            ->whereDoesntHave('result')
            ->whereNotNull('target_pace_seconds_per_km')
            ->each(function (TrainingDay $day) use ($factor) {
                $goal = $day->trainingWeek?->goal;
                if ($goal && $goal->target_date && $day->date->isSameDay($goal->target_date)) {
                    return;
                }
                $day->update([
                    'target_pace_seconds_per_km' => (int) round($day->target_pace_seconds_per_km * $factor),
                ]);
            });
    }
}
