<?php

namespace App\Ai\Agents;

use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

class ActivityFeedbackAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return <<<'PROMPT'
You are a running coach reviewing a completed run. In 4-6 sentences, comment on:
- pace progression across the per-km splits (steady, negative-split, fading?),
- form vs the last 5 runs (HR/pace drift at similar efforts — improving fitness or accumulating fatigue),
- how well the run matched the planned workout.
Reference actual numbers. Be specific and constructive, not generic.
PROMPT;
    }
}
