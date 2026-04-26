<?php

namespace App\Http\Controllers;

use App\Http\Requests\GeneratePlanRequest;
use App\Jobs\GeneratePlan;
use App\Models\PlanGeneration;
use App\Services\RunningProfileService;
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
     * Activities arrive via POST /wearable/activities (HealthKit push from
     * the app) before this endpoint is called, so we never trigger any sync
     * here — we just check whether the user has any activities locally and
     * either compute the profile from them or return ready+empty.
     */
    public function profile(Request $request, RunningProfileService $profiles): JsonResponse
    {
        $user = $request->user();

        $profile = $profiles->getOrAnalyze($user);

        if ($profile === null) {
            // No activities synced yet (HealthKit push hasn't happened or
            // returned zero runs). Return ready+empty so the UI can proceed.
            return response()->json([
                'status' => 'ready',
                'analyzed_at' => null,
                'data_start_date' => null,
                'data_end_date' => null,
                'metrics' => [],
                'narrative_summary' => null,
                'personal_records' => $user->personal_records,
            ]);
        }

        return response()->json([
            'status' => 'ready',
            'analyzed_at' => $profile->analyzed_at,
            'data_start_date' => $profile->data_start_date,
            'data_end_date' => $profile->data_end_date,
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
            'personal_records' => $user->personal_records,
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
