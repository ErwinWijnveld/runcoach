<?php

namespace App\Ai\Tools;

use App\Ai\Agents\PlanVerifierAgent;
use App\Enums\GoalStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Support\PlanPayload;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Agent-in-the-loop plan auditor. After `create_schedule` or `edit_schedule`
 * generate/mutate a proposal, the main agent calls this to let a separate
 * coach-auditor (PlanVerifierAgent) sanity-check the plan against the
 * runner's profile and a short list of coaching principles the
 * deterministic optimizer CANNOT check.
 *
 * The cycle cap is enforced server-side via cache — even if the main
 * agent ignores the prompt instructions, the tool refuses to call the AI
 * past MAX_CYCLES per user within a generation session. The counter is
 * keyed to user_id (not proposal_id, since edit_schedule supersedes the
 * pending proposal on every call) and is reset by `create_schedule` on
 * fresh plan generations.
 */
class VerifyPlan implements Tool
{
    private const MAX_CYCLES = 2;

    /** Cache key prefix for the per-user verify cycle counter. */
    private const CYCLE_CACHE_PREFIX = 'verify_plan:cycle:user:';

    /** How long the counter stays alive while idle. */
    private const CYCLE_TTL_SECONDS = 3600;

    /**
     * Cache key for the per-user cycle counter. Scoped to the user, not to
     * an individual proposal id, because `edit_schedule` now supersedes
     * the pending proposal on every call — so a per-proposal key would
     * reset every single verify/edit turn and the cap would never fire
     * mid-loop. `create_schedule` resets this to 0 explicitly, so a brand
     * new plan generation always starts fresh.
     */
    public static function cycleCacheKey(int $userId): string
    {
        return self::CYCLE_CACHE_PREFIX.$userId;
    }

    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Audit the runner's latest pending proposal (or active plan, if no pending proposal) against their fitness profile and coaching principles the deterministic optimizer CANNOT check. Returns a JSON verdict: `{passed, summary, issues[], cycle, max_cycles}`.

        MANDATORY after every `create_schedule` or `edit_schedule` — don't present a plan to the runner until `verify_plan` returns `passed: true` OR `cycle >= max_cycles`.

        Loop:
        1. Call `verify_plan`.
        2. If `passed: false`, feed every `issues[].suggested_fix` into ONE `edit_schedule` call (batch the ops).
        3. Call `verify_plan` again.
        4. Stop when `passed: true` OR `cycle >= max_cycles`. If the cap is hit while still failing, present the plan with a short honest note about the remaining issues.

        Only `critical` and `major` issues fail the plan. `minor` findings are informational — fix if cheap, ignore if controversial.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [];
    }

    public function handle(Request $request): string
    {
        $target = $this->resolveTarget();
        if ($target === null) {
            return json_encode([
                'error' => 'No pending proposal or active plan to verify. Generate one first with create_schedule.',
            ]);
        }

        [$payload, $source] = $target;

        $cacheKey = self::cycleCacheKey($this->user->id);
        $previousCycles = (int) Cache::get($cacheKey, 0);
        $currentCycle = $previousCycles + 1;
        Cache::put($cacheKey, $currentCycle, self::CYCLE_TTL_SECONDS);

        // Hard server-side cap. Refuse to burn more AI calls on the same
        // proposal even if the main agent ignores max_cycles in its prompt.
        if ($currentCycle > self::MAX_CYCLES) {
            return json_encode([
                'passed' => true,
                'summary' => 'Max verification cycles reached; presenting the plan as-is.',
                'issues' => [],
                'cycle' => $currentCycle,
                'max_cycles' => self::MAX_CYCLES,
                'capped' => true,
                'source' => $source,
                'plan_structure' => PlanPayload::weekStructure($payload),
            ]);
        }

        $prompt = $this->buildPrompt($payload);
        $response = PlanVerifierAgent::make()->prompt($prompt);
        $verdict = $this->parseVerdict($response->text);

        if ($verdict === null) {
            Log::warning('VerifyPlan: unparseable verifier response', [
                'user_id' => $this->user->id,
                'response' => mb_substr($response->text, 0, 500),
            ]);

            return json_encode([
                'passed' => true,
                'summary' => 'Verifier returned an unparseable response; treating the plan as acceptable.',
                'issues' => [],
                'cycle' => $currentCycle,
                'max_cycles' => self::MAX_CYCLES,
                'source' => $source,
                'plan_structure' => PlanPayload::weekStructure($payload),
            ]);
        }

        return json_encode(array_merge($verdict, [
            'cycle' => $currentCycle,
            'max_cycles' => self::MAX_CYCLES,
            'source' => $source,
            'plan_structure' => PlanPayload::weekStructure($payload),
        ]));
    }

    /**
     * @return array{0: array<string, mixed>, 1: string}|null
     *                                                        Tuple of (payload, source label).
     */
    private function resolveTarget(): ?array
    {
        // Pending proposal — covers both `CreateSchedule` (new plan) and
        // `EditActivePlan` (edit proposal targeting the user's live goal).
        // `ModifySchedule` (single-day tweaks via training_day_id) is
        // intentionally skipped — it's too granular to be worth an AI audit.
        $pending = CoachProposal::where('user_id', $this->user->id)
            ->where('status', ProposalStatus::Pending)
            ->whereIn('type', [
                ProposalType::CreateSchedule,
                ProposalType::EditActivePlan,
            ])
            ->latest('id')
            ->first();
        if ($pending) {
            return [$pending->payload, 'pending_proposal'];
        }

        $goal = $this->user->goals()->where('status', GoalStatus::Active)->latest('id')->first();
        if ($goal) {
            return [PlanPayload::fromGoal($goal), 'active_goal'];
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function buildPrompt(array $payload): string
    {
        $profile = $this->user->runningProfile()->first();
        $metrics = $profile?->metrics ?? [];

        $volume = $metrics['weekly_avg_km'] ?? 'unknown';
        $pace = $metrics['avg_pace_seconds_per_km'] ?? 'unknown';
        $runs = $metrics['weekly_avg_runs'] ?? 'unknown';
        $consistency = $metrics['consistency_score'] ?? 'unknown';

        $goalName = $payload['goal_name'] ?? 'Untitled goal';
        $goalType = $payload['goal_type'] ?? 'unknown';
        $distance = $payload['distance'] ?? 'null';
        $targetDate = $payload['target_date'] ?? 'null';
        $goalTime = $payload['goal_time_seconds'] ?? 'null';

        $weeks = $payload['schedule']['weeks'] ?? [];
        $planJson = json_encode(['weeks' => $weeks], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

        return <<<PROMPT
Runner profile (rolling 12 months):
- Weekly volume: {$volume} km
- Typical pace: {$pace} sec/km
- Runs per week: {$runs}
- Consistency score: {$consistency}/100

Goal:
- Name: {$goalName}
- Type: {$goalType}
- Distance: {$distance}
- Target date: {$targetDate}
- Goal time (seconds): {$goalTime}

Plan to audit (JSON):
{$planJson}

Return your verdict JSON now.
PROMPT;
    }

    /**
     * @return array<string, mixed>|null
     */
    private function parseVerdict(string $raw): ?array
    {
        $text = trim($raw);
        if ($text === '') {
            return null;
        }

        // Strip ```json fences if the model ignored our instruction.
        $text = preg_replace('/^```(?:json)?\s*|\s*```$/m', '', $text) ?? $text;
        $text = trim($text);

        $decoded = json_decode($text, true);
        if (! is_array($decoded)) {
            return null;
        }

        $passed = (bool) ($decoded['passed'] ?? false);
        $summary = (string) ($decoded['summary'] ?? '');
        $issues = is_array($decoded['issues'] ?? null) ? $decoded['issues'] : [];

        $normalized = [];
        foreach ($issues as $issue) {
            if (! is_array($issue)) {
                continue;
            }
            $normalized[] = [
                'severity' => (string) ($issue['severity'] ?? 'minor'),
                'area' => (string) ($issue['area'] ?? 'structure'),
                'week' => isset($issue['week']) ? (int) $issue['week'] : null,
                'day_of_week' => isset($issue['day_of_week']) ? (int) $issue['day_of_week'] : null,
                'description' => (string) ($issue['description'] ?? ''),
                'suggested_fix' => (string) ($issue['suggested_fix'] ?? ''),
            ];
        }

        return [
            'passed' => $passed,
            'summary' => $summary,
            'issues' => $normalized,
        ];
    }
}
