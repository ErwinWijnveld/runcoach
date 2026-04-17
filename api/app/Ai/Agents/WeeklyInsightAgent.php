<?php

namespace App\Ai\Agents;

use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

class WeeklyInsightAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return 'You are a running coach giving a brief weekly insight. Be encouraging, specific, and concise (2-3 sentences max). Reference the runner\'s actual numbers and give one forward-looking tip.';
    }
}
