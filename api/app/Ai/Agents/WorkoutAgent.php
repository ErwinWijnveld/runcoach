<?php

namespace App\Ai\Agents;

use App\Ai\Tools\EditWorkout;
use App\Ai\Tools\EscalateToCoach;
use App\Ai\Tools\GetActivityDetails;
use App\Ai\Tools\GetRecentRuns;
use App\Ai\Tools\RescheduleWorkout;
use App\Ai\Tools\SearchActivities;
use App\Enums\CoachStyle;
use App\Models\TrainingDay;
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

/**
 * Per-training-day chat agent. Scoped narrowly to ONE workout: it can
 * answer questions about it, edit its targets, reschedule it, and pull
 * comparable runs from history. Anything broader (multi-day plan changes,
 * goal edits, generic coaching) is handed off to the full coach via
 * `escalate_to_coach`.
 *
 * Binding: every workout conversation has `subject_type='training_day'`
 * and `subject_id=<TrainingDay.id>` set on `agent_conversations`. The
 * agent looks that up at prompt time, eager loads result + week + goal
 * + matched activity, and bakes it into the system prompt — no tool
 * call needed to read the day itself.
 */
#[Timeout(120)]
class WorkoutAgent implements Agent, Conversational, HasTools
{
    use Promptable, RemembersConversations;

    public function __construct(private User $user) {}

    public function instructions(): string
    {
        $day = $this->resolveDay();
        $today = now()->format('Y-m-d (l)');
        $style = $this->user->coach_style?->value ?? CoachStyle::Balanced->value;

        if ($day === null) {
            return <<<PROMPT
            You are RunCoach Workout. Today is {$today}. The workout this chat is supposed to be about is missing or has been deleted. Briefly let the runner know, and call `escalate_to_coach` with their request so they can continue with the full coach.
            PROMPT;
        }

        $context = $this->buildDayContext($day);
        $mutationsAllowed = $this->planMutationsAllowed();
        $editLine = $mutationsAllowed
            ? "- Edits to THIS day's distance/pace/type/intervals/HR zone → call `edit_workout`. Returns a proposal for the runner to approve."
            : '- Plan edits are managed by your human coach. Suggest the change in plain prose and call `escalate_to_coach`.';
        $rescheduleLine = $mutationsAllowed
            ? '- Move THIS day to a different date → call `reschedule_workout`. Refuses race day and completed days; if it errors, escalate.'
            : '- Date moves are managed by your human coach. Suggest the move in prose and call `escalate_to_coach`.';

        return <<<PROMPT
        You are RunCoach Workout, a focused assistant for a SINGLE training day. Today is {$today}.

        ## Coach style: {$style}
        Adapt your tone (motivational = encouragement-first, analytical = numbers-first, balanced = both). Keep replies to 1-3 short sentences unless the runner asks for detail.

        ## The workout you are talking about
        {$context}

        ## Your scope — strict
        You handle ONLY this workout:
        - Answer questions about its purpose, structure, pacing, what success looks like.
        - Compare it to the runner's other recent runs when useful (use `get_recent_runs`, `search_activities`, `get_activity_details`).
        {$editLine}
        {$rescheduleLine}

        Anything broader → call `escalate_to_coach` with a one-sentence first-person restatement of the runner's ask. Examples that escalate:
        - "Build me a marathon plan" / "redo my whole schedule"
        - "Move next week's long run too"
        - "Change my goal date / distance / coach style"
        - Broad analysis across many weeks of training

        After calling `escalate_to_coach`, end your turn with one short sentence (e.g. "Routing you to the full coach for that — tap below.") so the runner knows what's happening. Do NOT continue trying to answer the broader request yourself.

        ## When the runner asks about the result of this workout
        If the day is completed, the actual stats and AI feedback are above — use them directly. You don't need a tool call to know how the run went. Use `get_activity_details` only if the runner asks for per-km splits or HR curve detail.

        ## Tool usage
        - Always fetch data before quoting numbers; never invent paces or distances.
        - For "compare to last X" questions, call `search_activities` (date-ranged) or `get_recent_runs` (latest N), then quote specific numbers.
        - For per-km splits / HR curve on a specific past run, first call `get_recent_runs` or `search_activities` to find the activity_id, then `get_activity_details`.

        ## Response format
        - Plain prose, no markdown headings, at most one short bulleted list.
        - Specific numbers: "your 6.2km on Tuesday at 5:18/km" beats "your recent runs".
        - Never use em-dashes (—). Use commas, periods, parentheses, or hyphens.
        PROMPT;
    }

    public function tools(): iterable
    {
        $day = $this->resolveDay();

        $tools = [
            new GetRecentRuns($this->user),
            new SearchActivities($this->user),
            new GetActivityDetails($this->user),
            new EscalateToCoach,
        ];

        if ($day !== null && $this->planMutationsAllowed()) {
            $tools[] = new EditWorkout(
                $this->user,
                $day,
                app(PlanOptimizerService::class),
                app(ProposalService::class),
            );
            $tools[] = new RescheduleWorkout($this->user, $day);
        }

        return $tools;
    }

    private function resolveDay(): ?TrainingDay
    {
        if (! $this->conversationId) {
            return null;
        }

        $row = DB::table('agent_conversations')
            ->where('id', $this->conversationId)
            ->first(['subject_type', 'subject_id']);

        if ($row === null || $row->subject_type !== 'training_day' || $row->subject_id === null) {
            return null;
        }

        return TrainingDay::with(['result.wearableActivity', 'trainingWeek.goal'])->find((int) $row->subject_id);
    }

    private function buildDayContext(TrainingDay $day): string
    {
        $week = $day->trainingWeek;
        $goal = $week?->goal;
        $result = $day->result;

        $date = $day->date instanceof Carbon
            ? $day->date->format('Y-m-d (l)')
            : (string) $day->date;
        $type = $day->type?->label() ?? 'Run';
        $title = $day->title ?: $type;

        $status = $this->status($day);

        $lines = [
            "- title: {$title}",
            "- date: {$date}",
            "- type: {$type}",
            '- target_km: '.($day->target_km !== null ? (string) $day->target_km : 'unset'),
            '- target_pace_seconds_per_km: '.($day->target_pace_seconds_per_km ?? 'unset'),
            '- target_heart_rate_zone: '.($day->target_heart_rate_zone ? "Z{$day->target_heart_rate_zone}" : 'unset'),
            "- status: {$status}",
            '- training_week: '.($week ? "week {$week->week_number} of \"{$goal?->name}\"" : 'unattached'),
            '- goal: '.($goal ? "{$goal->name} (target_date: ".($goal->target_date?->toDateString() ?? 'open').')' : 'unattached'),
        ];

        if (! empty($day->description)) {
            $lines[] = '- description: '.trim((string) $day->description);
        }

        $intervals = $day->intervals_json;
        if (is_array($intervals) && count($intervals) > 0) {
            $lines[] = '- intervals: '.json_encode($intervals);
        }

        if ($result !== null) {
            $lines[] = '';
            $lines[] = '## Logged result for this workout';
            $lines[] = '- compliance_score (0-10): '.($result->compliance_score ?? 'unset');
            $lines[] = '- distance_score (0-10): '.($result->distance_score ?? 'unset');
            $lines[] = '- pace_score (0-10): '.($result->pace_score ?? 'unset');
            $lines[] = '- heart_rate_score (0-10): '.($result->heart_rate_score ?? 'unset');
            $lines[] = '- actual_km: '.($result->actual_km ?? 'unset');
            $lines[] = '- actual_pace_seconds_per_km: '.($result->actual_pace_seconds_per_km ?? 'unset');
            $lines[] = '- actual_avg_heart_rate: '.($result->actual_avg_heart_rate ?? 'unset');

            $activity = $result->wearableActivity;
            if ($activity !== null) {
                $lines[] = '- matched_activity_id: '.$activity->id.' (use get_activity_details if the runner asks for splits or HR curve)';
                $lines[] = '- matched_activity_source: '.$activity->source;
                if ($activity->start_date !== null) {
                    $lines[] = '- matched_activity_started_at: '.Carbon::parse($activity->start_date)->toIso8601String();
                }
            }

            $feedback = trim((string) ($result->ai_feedback ?? ''));
            if ($feedback !== '') {
                $lines[] = '';
                $lines[] = '## AI feedback already shown to the runner';
                $lines[] = $feedback;
                $lines[] = '';
                $lines[] = '(Don\'t repeat this verbatim — build on it. The runner has seen it.)';
            }
        }

        return implode("\n", $lines);
    }

    private function status(TrainingDay $day): string
    {
        if ($day->result()->exists()) {
            return 'completed';
        }
        if ($day->date === null) {
            return 'unscheduled';
        }
        $today = now()->startOfDay();
        $date = Carbon::parse($day->date)->startOfDay();
        if ($date->equalTo($today)) {
            return 'today';
        }
        if ($date->lt($today)) {
            return 'missed';
        }

        return 'upcoming';
    }

    /**
     * False when the user is an active client of an organization that has
     * `coaches_own_plans = true` — same logic as RunCoachAgent.
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
}
