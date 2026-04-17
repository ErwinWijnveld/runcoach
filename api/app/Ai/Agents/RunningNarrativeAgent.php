<?php

namespace App\Ai\Agents;

use Laravel\Ai\Attributes\Temperature;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

#[Temperature(0.4)]
class RunningNarrativeAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return 'You are a running coach summarising 12 months of activity in ONE short paragraph (max 3 sentences). Mention consistency, pace feel, and progression. Do NOT invent numbers — only refer to what is in the metrics.';
    }
}
