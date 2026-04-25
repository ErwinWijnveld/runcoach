<?php

namespace App\Http\Controllers;

use App\Http\Requests\GeneratePlanRequest;
use App\Jobs\GeneratePlan;
use App\Jobs\SyncStravaHistory;
use App\Models\PlanGeneration;
use App\Services\RunningProfileService;
use App\Services\StravaSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    /**
     * Ensure an onboarding conversation exists for the user. Returns its id.
     * Idempotent: returns the existing onboarding conversation if one is open.
     *
     * The frontend then mounts CoachChatView pointed at this conversation and
     * sends its first message via the regular /coach/chat endpoint. The agent,
     * reading `context='onboarding'`, follows the onboarding script.
     *
     * @deprecated Replaced by the form-based onboarding flow
     *             (GET /onboarding/profile + POST /onboarding/generate-plan).
     *             Kept temporarily for backwards compatibility with older app builds.
     */
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();

        $existing = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();

        if ($existing !== null) {
            return response()->json(['conversation_id' => $existing->id]);
        }

        $conversationId = (string) Str::uuid();
        $now = now();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['conversation_id' => $conversationId]);
    }

    /**
     * Returns the user's running profile for the onboarding overview screen.
     *
     * If no Strava activities are synced yet, runs the sync INLINE (synchronous)
     * before returning. The user is already blocked on a spinner during onboarding
     * so the async-job + poll pattern only adds 3-6s of wakeup/poll lag without
     * any UX benefit. After onboarding (manual sync, dashboard pulls) the queued
     * `SyncStravaHistory::dispatch()` path is still used — see `StravaController`
     * and `DashboardController`.
     */
    public function profile(
        Request $request,
        RunningProfileService $profiles,
        StravaSyncService $stravaSyncService,
    ): JsonResponse {
        $user = $request->user();

        if (! $user->stravaActivities()->exists()) {
            (new SyncStravaHistory($user->id))->handle($stravaSyncService);
        }

        $profile = $profiles->getOrAnalyze($user);

        if ($profile === null) {
            // Sync ran but produced zero runs (e.g. user has no run activities
            // in the last 3 months). Treat as ready with empty metrics so the
            // UI can proceed instead of polling forever.
            return response()->json([
                'status' => 'ready',
                'analyzed_at' => null,
                'data_start_date' => null,
                'data_end_date' => null,
                'metrics' => [],
                'narrative_summary' => null,
            ]);
        }

        return response()->json([
            'status' => 'ready',
            'analyzed_at' => $profile->analyzed_at,
            'data_start_date' => $profile->data_start_date,
            'data_end_date' => $profile->data_end_date,
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }

    /**
     * Enqueue plan generation. Idempotent: if a row is already in flight for
     * this user, returns it without dispatching a second job. Generation runs
     * in the queue worker (~60-110s); the client polls latestPlanGeneration().
     */
    public function generatePlan(GeneratePlanRequest $request): JsonResponse
    {
        $user = $request->user();
        $existing = $user->pendingPlanGeneration();

        if ($existing !== null && $existing->isInFlight()) {
            return response()->json(self::serialize($existing), 202);
        }

        $row = PlanGeneration::create([
            'user_id' => $user->id,
            'status' => 'queued',
            'payload' => $request->validated(),
        ]);

        GeneratePlan::dispatch($row->id);

        return response()->json(self::serialize($row), 202);
    }

    /**
     * Return the user's latest user-actionable plan generation, or 204 if
     * none. The Flutter generating screen polls this every 3s.
     */
    public function latestPlanGeneration(Request $request): JsonResponse|Response
    {
        $row = $request->user()->pendingPlanGeneration();

        if ($row === null) {
            return response()->noContent();
        }

        return response()->json(self::serialize($row));
    }

    /**
     * @return array<string, mixed>
     */
    public static function serialize(PlanGeneration $row): array
    {
        return [
            'id' => $row->id,
            'status' => $row->status->value,
            'conversation_id' => $row->conversation_id,
            'proposal_id' => $row->proposal_id,
            'error_message' => $row->error_message,
        ];
    }
}
