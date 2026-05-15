<?php

namespace App\Http\Controllers;

use App\Enums\PaceDerivation;
use App\Http\Requests\GeneratePlanRequest;
use App\Http\Requests\SelfReportedStatsRequest;
use App\Jobs\GeneratePlan;
use App\Models\PlanGeneration;
use App\Models\User;
use App\Services\Onboarding\FitnessSnapshotService;
use App\Services\RunningProfileService;
use App\Support\Onboarding\FitnessSnapshot;
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
    public function profile(
        Request $request,
        RunningProfileService $profiles,
        FitnessSnapshotService $fitness,
    ): JsonResponse {
        $user = $request->user();

        $profile = $profiles->getOrAnalyze($user);
        $snapshot = $fitness->snapshot($user);
        $baseline = $this->buildBaseline($user, $snapshot);

        // Empty PHP array would JSON-encode as `[]` and break the Flutter
        // Map<String, dynamic>? parse. Force null so the field round-trips
        // as JSON null (which Flutter handles cleanly).
        $personalRecords = $user->personal_records ?: null;

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
                'personal_records' => $personalRecords,
                'baseline' => $baseline,
            ]);
        }

        return response()->json([
            'status' => 'ready',
            'analyzed_at' => $profile->analyzed_at,
            'data_start_date' => $profile->data_start_date,
            'data_end_date' => $profile->data_end_date,
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
            'personal_records' => $personalRecords,
            'baseline' => $baseline,
        ]);
    }

    /**
     * Build the baseline block surfaced by the onboarding overview screen so
     * Flutter can decide per-field lock state. Source is `self_reported`
     * when the column is set; otherwise `apple_health` when the cascade had
     * real signal; otherwise null. Values are only emitted when source is
     * non-null — Tier-4 fallback numbers must NOT leak into the form, or the
     * runner ends up with a "prefilled" baseline they never confirmed.
     *
     * @return array{
     *   weekly_km: float|null,
     *   weekly_km_source: string|null,
     *   easy_pace_seconds_per_km: int|null,
     *   easy_pace_source: string|null,
     * }
     */
    private function buildBaseline(User $user, FitnessSnapshot $snapshot): array
    {
        $weeklyKmSource = match (true) {
            $user->self_reported_weekly_km !== null => 'self_reported',
            $snapshot->weeklyKmRecent4Weeks > 0 => 'apple_health',
            default => null,
        };

        $weeklyKm = match ($weeklyKmSource) {
            'self_reported' => (float) $user->self_reported_weekly_km,
            'apple_health' => round($snapshot->weeklyKmRecent4Weeks, 1),
            default => null,
        };

        $easyPaceSource = match (true) {
            $user->self_reported_easy_pace_seconds_per_km !== null => 'self_reported',
            $snapshot->derivation !== PaceDerivation::Fallback
                && $snapshot->derivation !== PaceDerivation::SelfReported => 'apple_health',
            default => null,
        };

        $easyPace = match ($easyPaceSource) {
            'self_reported' => (int) $user->self_reported_easy_pace_seconds_per_km,
            'apple_health' => $snapshot->easyPaceSecondsPerKm,
            default => null,
        };

        return [
            'weekly_km' => $weeklyKm,
            'weekly_km_source' => $weeklyKmSource,
            'easy_pace_seconds_per_km' => $easyPace,
            'easy_pace_source' => $easyPaceSource,
        ];
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
     * Persist the runner's self-reported baseline stats from the onboarding
     * overview screen. Either field may be null (wearable user with that
     * field still locked); writing both nulls clears the timestamp too so
     * subsequent reads fall back to the cascade.
     */
    public function saveSelfReportedStats(SelfReportedStatsRequest $request): JsonResponse
    {
        $user = $request->user();
        $weeklyKm = $request->validated('weekly_km');
        $easyPace = $request->validated('easy_pace_seconds_per_km');
        $touched = $weeklyKm !== null || $easyPace !== null;

        $user->update([
            'self_reported_weekly_km' => $weeklyKm,
            'self_reported_easy_pace_seconds_per_km' => $easyPace,
            'self_reported_stats_at' => $touched ? now() : null,
        ]);

        return response()->json(['status' => 'saved']);
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
