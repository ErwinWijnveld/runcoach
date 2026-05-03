<?php

namespace App\Ai\Tools;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Pure UI signal. The workout-scoped agent calls this when the runner asks
 * for something outside its lane (multi-day plan changes, goal/style edits,
 * broad coaching). The streaming layer detects the `display: 'handoff'`
 * marker and emits a `data-handoff` SSE event; the Flutter sheet then
 * renders a "Ask the full coach" button that opens a fresh coach chat
 * pre-seeded with the suggested prompt.
 */
class EscalateToCoach implements Tool
{
    public function description(): string
    {
        return <<<'DESC'
        Hand the runner off to the full coach when their request is outside this workout's scope. Returns a UI signal — does NOT mutate state and does NOT reply to the runner. After calling this, end your turn with one short sentence acknowledging the handoff.

        USE THIS for requests like:
        - "Build me a marathon plan" / "rebuild my whole schedule"
        - "Change my goal date" / "switch to a different distance"
        - "Move next week's long run" (more than this single day)
        - "How is my training going overall?" (broad cross-week analysis)
        - "What should my coach style be?"
        - Any change touching MULTIPLE training days at once

        DO NOT use for things you CAN handle yourself:
        - Edits to THIS workout's distance/pace/type/intervals → use `edit_workout`
        - Moving THIS workout to another date → use `reschedule_workout`
        - Questions about THIS workout or comparisons against other recent runs → answer directly using `get_recent_runs` / `search_activities` / `get_activity_details`

        `suggested_prompt` becomes the first message of the coach chat the runner lands in — make it a concise, faithful restatement of what they asked, written in first person from the runner's perspective ("Can you build me a marathon plan?").
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'suggested_prompt' => $schema->string()->required()->description('First-person restatement of the runner\'s request, sent as the first message in the new coach chat. ≤ 200 chars.'),
        ];
    }

    public function handle(Request $request): string
    {
        $prompt = trim((string) ($request['suggested_prompt'] ?? ''));
        if ($prompt === '') {
            return json_encode(['error' => 'suggested_prompt is required']);
        }

        return json_encode([
            'display' => 'handoff',
            'requires_handoff' => true,
            'suggested_prompt' => mb_substr($prompt, 0, 500),
        ]);
    }
}
