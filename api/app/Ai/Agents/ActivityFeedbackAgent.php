<?php

namespace App\Ai\Agents;

use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

class ActivityFeedbackAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return 'You are a running coach giving brief post-run feedback. Be specific, constructive, and concise (2-3 sentences max). Reference the actual numbers.';
    }
}
