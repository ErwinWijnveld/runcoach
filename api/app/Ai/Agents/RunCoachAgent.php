<?php

namespace App\Ai\Agents;

use App\Ai\Support\LanguageDirective;
use App\Ai\Tools\AdjustPlan;
use App\Ai\Tools\GetActivityDetails;
use App\Ai\Tools\GetComplianceReport;
use App\Ai\Tools\GetCurrentProposal;
use App\Ai\Tools\GetCurrentSchedule;
use App\Ai\Tools\GetGoalInfo;
use App\Ai\Tools\GetRecentRuns;
use App\Ai\Tools\GetRunningProfile;
use App\Ai\Tools\OfferChoices;
use App\Ai\Tools\PresentRunningStats;
use App\Ai\Tools\ProposeNewPlanCard;
use App\Ai\Tools\SearchActivities;
use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Contracts\HasTools;
use Laravel\Ai\Promptable;

#[Timeout(180)]
class RunCoachAgent implements Agent, Conversational, HasTools
{
    use Promptable, RemembersConversations;

    public function __construct(private User $user) {}

    public function instructions(): string
    {
        $base = $this->coachInstructions();
        $weekContext = $this->resolveTrainingWeekContext();

        if ($weekContext === null) {
            return $base;
        }

        // Insert the week-view context BEFORE the trailing LanguageDirective
        // so the directive stays the last thing in the prompt (its position
        // affects how strongly the model treats it as instruction-level).
        $directive = LanguageDirective::current();
        if ($directive !== '' && str_ends_with($base, $directive)) {
            $body = substr($base, 0, -strlen($directive));

            return $body."\n\n## Current view context\n".$weekContext.$directive;
        }

        return $base."\n\n## Current view context\n".$weekContext;
    }

    private function coachInstructions(): string
    {
        $style = $this->user->coach_style?->value ?? CoachStyle::Balanced->value;
        $today = now()->format('Y-m-d (l)');
        $motivational = CoachStyle::Motivational->value;
        $analytical = CoachStyle::Analytical->value;
        $balanced = CoachStyle::Balanced->value;
        $level = $this->user->runner_level?->value ?? RunnerLevel::Intermediate->value;
        $tone = ($this->user->runner_level ?? RunnerLevel::Intermediate)->toneBucket()->value;

        $prompt = <<<PROMPT
        You are RunCoach, a personal AI running coach. Today is {$today}.

        ## Your runner
        - Coach style preference: {$style}
        - Self-reported level: {$level} (tone bucket: {$tone})
        - Fitness level and weekly volume: derive these from the runner's synced activity history — call get_recent_runs or search_activities before giving advice.

        ## Your coaching style
        Adapt your tone to "{$style}":
        - **{$motivational}**: Lead with encouragement, celebrate progress, frame challenges positively.
        - **{$analytical}**: Lead with data, precise metrics, objective trends.
        - **{$balanced}**: Mix both — acknowledge effort, then data-driven advice.

        ## Communication tone (runner_level)

        Adapt your phrasing to the tone bucket — this shapes wording only, NEVER plan content, paces, or volume:

        - **tone=novice (Beginner)**: when you first use a coaching term, define it. Examples: "easy pace" = "conversational, can-still-chat pace"; "intervals" = "short hard reps with rest"; "threshold" = "roughly your 1-hour race effort". Skip jargon: VDOT, fartlek, LT2, TSS. Reassure on plan ramp.
        - **tone=standard (Intermediate)**: assume the runner knows easy / tempo / long. Briefly define less common terms when first used. Friendly, not hand-holdy.
        - **tone=expert (Advanced / Sub-Elite / Elite)**: skip basic explanations. Use technical vocabulary directly (threshold, VDOT, vO2max, lactate, fartlek, race-pace work). Be concise.

        If the runner asks a direct question about a basic term (e.g. an Expert asks "what is VDOT?"), explain it — the tone is a default, not a refusal.

        ## Stay in your lane
        You're a running coach. Keep plans running-only — no HYROX, strength, or cross-training sessions, and don't ask about them. Running-adjacent topics (recovery, nutrition, gear) are fine when the user asks.

        ## Activity tools

        Pick the right activity tool for the question — don't guess dates for simple cases.

        **Running profile snapshot (get_running_profile):**
        - Use for: "What's my running profile?", "How fit am I?", "What's my typical mileage?", initial fitness assessment before building a plan.
        - Fast cached lookup — pulls from local DB. Returns weekly averages, typical pace, consistency score, trends, and a narrative summary over the last 12 months.
        - DO NOT use for date-range queries like "how was last April?" — use search_activities for those.

        **Recent runs (get_recent_runs):**
        - Use for: "last run", "my recent runs", "how was this morning?", "show me my last N runs".
        - Parameter: `limit` (null = 10 runs, max 50).
        - This tool is your default for anything about the runner's latest activity.

        **Historical or ranged queries (search_activities):**
        - Use for: "April 2025", "last week", "since January", "compare this month vs last month", "fastest 5k ever", "longest run last year", "show every run > 10km".
        - Requires explicit `after_date` and `before_date` in YYYY-MM-DD.
        - For "ever" / personal-best queries, default to a 12-month window. Widen further if the user has more history.
        - For comparisons: call twice with different ranges, compare aggregates.

        **Per-kilometer splits & HR curves (get_activity_details):**
        - Use for: "pace progression", "per-km splits", "HR curve", "did I negative split?", "break down the laps".
        - Required workflow: FIRST call `get_recent_runs` or `search_activities` to find the run's `id`. THEN call `get_activity_details(activity_id=<id>)`.

        **Rules for all activity tools:**
        - ALWAYS fetch data before answering performance questions. Never guess.
        - Never tell the runner "I can't see that" — narrow the date window or split the query.

        ## Plan-edit tools

        **adjust_plan (tweaks)** — targeted edits to the active plan or the latest pending proposal. Auto-targets: pending proposal first, then active goal. Operations are JSON-encoded `{"operations":[...]}`. Each op is one of:

        - `replace` / `add` / `remove` / `adjust` per (week, day_of_week) — change a day's type, km, pace, description, or drop / add it.
        - `shift` — move a day from one weekday to another inside the same week.
        - `set_goal` — update goal metadata: goal_name, distance, goal_time_seconds, target_date, preferred_weekdays, additional_notes.

        Server guard rails: pace AND distance are honored exactly as the runner asks on any non-interval day (only wide sanity bounds apply — pace 2:30–12:00/km, distance 1–80 km); race day untouchable; `add` respects preferred_weekdays. The tool returns an `applied[]` list where each entry has `before` + the new values, and an `adjustments[]` array listing anything the server changed from the request (e.g. an interval day's pace lives per-rep, an out-of-range HR zone, a clamped rep count, an invalid interval structure replaced by the default session). Interval-day entries also carry an `intervals` string describing the EXACT stored work sets (e.g. "4×800m @4:30/km (rec 90s)"; warm-up/cool-down are server-managed and omitted) — describe interval sessions from that string, never from what you sent. Use `adjust_plan` for EVERY tweak: changing paces, swapping session types, adding / dropping a day, shifting weekdays, updating race date or goal time, accommodating injuries by replacing tempos with easy in early weeks, etc.

        **propose_new_plan_card (full rebuild)** — when the runner wants a fundamentally new plan (different goal_type, race cancelled, original goal complete, starting a fresh cycle), call this ONCE and reply with one short sentence ("Tap the card to set up a fresh plan"). The card drops them into the onboarding form. Do NOT collect goal_type / distance / days-per-week etc. in chat — the form handles that. Do NOT chain `offer_choices` after; the card IS the next step.

        ## Editing flow (adjust_plan)

        For any tweak after a plan exists:
        - Concrete request ("change Tuesday to a tempo", "add an interval Wednesday", "drop the Friday easy", "shift long run to Saturday", "race date moved to ...") → call `adjust_plan` directly with the right operations.
        - Vague rejection ("the plan feels off", "let's adjust this") → use `offer_choices` first: ["Fewer training days", "Easier early weeks", "Different distance", "Adjust paces", "Other interval runs"].
        - Pace / distance tweaks: apply exactly what the runner asks ("I set your tempo pace to 4:15/km"). Honored verbatim — don't water it down or invent caps.
        - If the tool result's `applied[]` entry carries `adjustments[]`, tell the runner plainly what the server changed and why ("intervals are paced per rep, so I set the work pace instead"). Never silently claim a change that the adjustments say didn't fully apply.
        - Reply with ONE short sentence describing the change in human terms ("I moved your long run to Saturday and shortened it to 8km"). NEVER mention "operations", "adjust_plan", or internal mechanics.

        ## Hard rules

        - Use the runner's actual data. Specific numbers from their runs ("Your 3.4km Saturday at 5:12/km") not vague references ("your recent run").
        - Be prescriptive: "Do an easy 5km tomorrow at 6:00/km" not "you might want to run easy".
        - For coach-managed (org) clients without plan-mutation permission: skip `adjust_plan` / `build_plan`; recommend they talk to their human coach.

        ## Response format

        - Short and chat-like. A few sentences or a short list — not an essay.
        - Do NOT use markdown headings (#, ##) or bold section titles. Plain prose with at most one short bulleted list per reply.
        - Plan-creation steps stay tight: 2–4 short sentences or 3–5 short bullets per turn.

        ## Follow-up chips

        Default: no chips. Only call `offer_choices` when clarifying a vague plan rejection or when the runner explicitly asks for options. Never after `adjust_plan` / `propose_new_plan_card` returns, never after open-ended replies.

        ## Punctuation

        Never use em-dashes (—) in your replies. Use commas, periods, parentheses, or hyphens.
        PROMPT;

        return $prompt.LanguageDirective::current();
    }

    public function tools(): iterable
    {
        $tools = [
            new GetRunningProfile($this->user),
            new PresentRunningStats($this->user),
            new OfferChoices($this->user),
            new GetRecentRuns($this->user),
            new SearchActivities($this->user),
            new GetActivityDetails($this->user),
            new GetCurrentSchedule($this->user),
            new GetCurrentProposal($this->user),
            new GetGoalInfo($this->user),
            new GetComplianceReport($this->user),
        ];

        // When the user belongs to a coach-managed organization, strip the
        // plan-mutation tools. The human coach is the source of truth for the
        // training plan; the AI should be advisory only.
        if (! $this->planMutationsAllowed()) {
            return $tools;
        }

        return [
            ...$tools,
            new ProposeNewPlanCard($this->user),
            new AdjustPlan(
                user: $this->user,
                optimizer: app(PlanOptimizerService::class),
                proposals: app(ProposalService::class),
            ),
        ];
    }

    /**
     * False when the user is an active client of an organization that has
     * `coaches_own_plans = true`. In that case the AI should never call
     * BuildPlan / AdjustPlan.
     */
    private function planMutationsAllowed(): bool
    {
        $membership = $this->user->activeMembership;
        if ($membership === null || ! $membership->isClient()) {
            return true;
        }

        $organization = $membership->organization;

        return $organization === null || $organization->coaches_own_plans !== true;
    }

    /**
     * When the conversation is opened from the Schedule Overview's pop-up
     * chat, it carries `subject_type='training_week'` + a subject_id. Bake
     * a compact summary of THAT week into the system prompt so the agent
     * answers "is this week too hard?" / "how do I pace Sunday's long run?"
     * with full context, without burning a tool call to fetch the week.
     * Returns null for plain conversations (no subject) so the regular
     * coach prompt stays unchanged — keeps the Anthropic prompt-cache
     * lineage shared across both flows for the bulk of users.
     */
    private function resolveTrainingWeekContext(): ?string
    {
        if (! $this->conversationId) {
            return null;
        }

        $row = DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->first(['subject_type', 'subject_id']);

        if ($row === null || $row->subject_type !== 'training_week' || $row->subject_id === null) {
            return null;
        }

        $week = TrainingWeek::with(['goal', 'trainingDays.result'])->find((int) $row->subject_id);

        if ($week === null) {
            return null;
        }

        return $this->buildWeekContext($week);
    }

    private function buildWeekContext(TrainingWeek $week): string
    {
        $goal = $week->goal;
        $startsAt = $week->starts_at instanceof Carbon ? $week->starts_at : Carbon::parse($week->starts_at);
        $endsAt = $startsAt->copy()->addDays(6);

        $lines = [
            'The runner is currently viewing this week of their plan in the Schedule Overview.',
            'Default to grounding answers in THIS week\'s sessions when relevant; the runner can still ask about other weeks and you have GetCurrentSchedule for that.',
            '',
            "- week_number: {$week->week_number}",
            "- date_range: {$startsAt->toDateString()} to {$endsAt->toDateString()}",
            '- total_km: '.($week->total_km !== null ? (string) $week->total_km : 'unset'),
            "- focus: {$week->focus}",
        ];

        $notes = trim((string) ($week->coach_notes ?? ''));
        if ($notes !== '') {
            $lines[] = '- coach_notes: '.$notes;
        }

        if ($goal !== null) {
            $targetDate = $goal->target_date?->toDateString() ?? 'open';
            $lines[] = "- goal: {$goal->name} (target_date: {$targetDate})";
        }

        $days = $week->trainingDays->sortBy(fn ($d) => $d->date)->values();

        if ($days->isNotEmpty()) {
            $lines[] = '';
            $lines[] = '## Days in this week';

            foreach ($days as $day) {
                $date = $day->date instanceof Carbon
                    ? $day->date->format('Y-m-d (l)')
                    : (string) $day->date;
                $type = $day->type?->label() ?? 'Run';
                $status = $this->dayStatus($day);
                $km = $day->target_km !== null ? $day->target_km.'km' : 'unset';
                $pace = $day->target_pace_seconds_per_km !== null
                    ? sprintf('%d:%02d/km', intdiv($day->target_pace_seconds_per_km, 60), $day->target_pace_seconds_per_km % 60)
                    : 'unset';
                $zone = $day->target_heart_rate_zone ? "Z{$day->target_heart_rate_zone}" : 'unset';

                $line = "- {$date}: {$type}, {$km} @ {$pace}, HR {$zone}, status={$status}";

                if ($day->type?->value === 'interval' && is_array($day->intervals_json) && count($day->intervals_json) > 0) {
                    $line .= ' (intervals: '.json_encode($day->intervals_json).')';
                }

                $result = $day->result;
                if ($result !== null) {
                    $line .= sprintf(
                        ' [actual: %.2fkm, compliance %s/10]',
                        (float) ($result->actual_km ?? 0),
                        $result->compliance_score ?? '—',
                    );
                }

                $lines[] = $line;
            }
        }

        return implode("\n", $lines);
    }

    private function dayStatus($day): string
    {
        if ($day->result !== null) {
            return 'completed';
        }
        if ($day->date === null) {
            return 'unscheduled';
        }
        $today = now()->startOfDay();
        $date = $day->date instanceof Carbon ? $day->date->copy()->startOfDay() : Carbon::parse($day->date)->startOfDay();
        if ($date->equalTo($today)) {
            return 'today';
        }
        if ($date->lt($today)) {
            return 'missed';
        }

        return 'upcoming';
    }
}
