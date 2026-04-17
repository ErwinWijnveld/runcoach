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
        Render a row of tappable chip suggestions for the user. Use this when you have a short closed-list question: what distance, how many days per week, coach style, etc. The user can tap a chip OR type free text — both arrive back as a regular user message; you parse whichever. Provide 2–6 chips. Each chip has a display `label` and a machine-friendly `value`. Labels should be human (e.g. "Half marathon"); values should be stable keys (e.g. "half_marathon").

        DO NOT use this for the final plan proposal — use create_schedule for that.
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
                ->description('2–6 chip options. Each has `label` (human) and `value` (machine).')
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
