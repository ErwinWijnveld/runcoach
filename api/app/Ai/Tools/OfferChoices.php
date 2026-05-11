<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class OfferChoices implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'TXT'
        Render 2–4 tappable chip suggestions when your next turn has a small fixed answer set (closed-list questions like distance, days/week, or clarifying a vague plan rejection). Each chip has a human `label` and a machine `value`.

        Do not use after `build_plan` / `adjust_plan` returns, or for open-ended follow-ups. If unsure, no chips.
        TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'chips' => $schema->array()
                ->items(
                    $schema->object([
                        'label' => $schema->string()->required(),
                        'value' => $schema->string()->required(),
                    ])
                )
                ->description('2–4 chip options. Each has `label` (human) and `value` (machine).')
                ->required(),
        ];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'display' => 'chip_suggestions',
            'chips' => $request['chips'],
        ]);
    }
}
