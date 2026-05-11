<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

/**
 * Renders a "Start new training plan" card in chat with a CTA that drops
 * the runner back into the onboarding form (at goal_type step). Replaces
 * the multi-turn `offer_choices` chip flow that used to walk the runner
 * through goal_type → distance → race-date → days/week → notes in chat.
 *
 * The card is purely informational on the SSE wire — Flutter renders it
 * under the assistant message and handles the navigation on tap. No
 * proposal is persisted by this tool.
 */
class ProposeNewPlanCard implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'TXT'
        Render a "Start new training plan" card in the chat. Tap drops the runner into the onboarding form at the goal-type step (skipping connect-health / zones / overview since those are already set).

        USE THIS when the runner explicitly wants a new / fresh plan (different goal, race cancelled, starting a new training cycle). One tool call per turn; reply with ONE short sentence ("Tap the card to set up a fresh plan") — no chips, no follow-up questions.

        DO NOT USE for tweaks to an existing plan — use `adjust_plan` for those.
        TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'display' => 'new_plan_card',
            'entry_point' => 'goal_type',
        ]);
    }
}
