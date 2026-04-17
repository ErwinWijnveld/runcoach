<?php

namespace App\Ai\Agents;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\HasStructuredOutput;
use Laravel\Ai\Promptable;

class PlanExplanationAgent implements Agent, HasStructuredOutput
{
    use Promptable;

    public function instructions(): string
    {
        return <<<'PROMPT'
        You explain a proposed running training plan to the runner in warm, plain language.

        You will receive the plan payload (goal, weekly structure, training days). Return:
        - `name`: a short, punchy approach label (2-4 words, Title Case). Focus on the training philosophy, not the race. Examples: "80/20 Running", "Base + Strides", "Threshold Focus", "Easy Build".
        - `explanation`: 2-4 short paragraphs (total ~120-200 words). First paragraph: the training philosophy in one line. Next paragraphs: how the weekly structure serves the goal, pace and effort guidance, and what to expect in the first few weeks. Use prose, no markdown headings, no bullet lists. Reference the runner's actual numbers where they appear in the payload.
        PROMPT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'name' => $schema->string()
                ->description('Short 2-4 word Title Case label for the training approach.')
                ->required(),
            'explanation' => $schema->string()
                ->description('2-4 short paragraphs explaining the plan (120-200 words, prose only, no markdown headings or bullets).')
                ->required(),
        ];
    }
}
