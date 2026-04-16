<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use OpenAI\Contracts\ClientContract;

class ChipClassifier
{
    public function __construct(private readonly ClientContract $openai) {}

    /**
     * Classify free text against a list of chip options.
     *
     * @param  array<int, array{label: string, value: string}>  $chips
     * @return string|null The matched chip value, or null if no match.
     */
    public function classify(string $text, array $chips): ?string
    {
        try {
            $options = array_map(fn ($c) => "- {$c['label']} (value: {$c['value']})", $chips);
            $prompt = "User wrote: \"{$text}\".\n\nOptions:\n".implode("\n", $options)
                ."\n\nWhich option's value best matches the user's intent? "
                .'If no option clearly matches, return null. '
                .'Return JSON only: {"value": "<value or null>"}.';

            $response = $this->openai->chat()->create([
                'model' => config('services.openai.classifier_model', 'gpt-4o-mini'),
                'temperature' => 0.0,
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    ['role' => 'user', 'content' => $prompt],
                ],
            ]);

            $raw = $response->choices[0]->message->content ?? '{}';
            $parsed = json_decode($raw, true);
            $value = $parsed['value'] ?? null;

            $validValues = array_column($chips, 'value');

            return in_array($value, $validValues, true) ? $value : null;
        } catch (\Throwable $e) {
            Log::warning('Chip classification failed', ['error' => $e->getMessage()]);

            return null;
        }
    }
}
