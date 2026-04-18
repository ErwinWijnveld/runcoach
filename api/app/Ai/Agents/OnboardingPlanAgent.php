<?php

namespace App\Ai\Agents;

use Laravel\Ai\Attributes\Temperature;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Promptable;

/**
 * One-shot agent that turns a structured onboarding-form payload into a
 * training-schedule JSON. Called by OnboardingPlanGeneratorService — not
 * a conversational agent, no tools.
 */
#[Temperature(0.3)]
#[Timeout(180)]
class OnboardingPlanAgent implements Agent
{
    use Promptable;

    public function instructions(): string
    {
        return "You are an expert running coach. Given a runner's 12-month profile and a target goal, produce a training plan as a single JSON object. Use the runner's actual volume and pace; never invent numbers. Output ONLY the JSON object — no prose, no markdown fences.";
    }
}
