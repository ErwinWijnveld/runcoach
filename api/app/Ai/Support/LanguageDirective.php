<?php

namespace App\Ai\Support;

use Illuminate\Support\Facades\App;

/**
 * Single source of truth for the trailing language directive appended to
 * every agent's system prompt.
 *
 * The system prompts themselves stay English regardless of locale — this
 * keeps the Anthropic prompt-cache (system + tools, see
 * AnthropicPromptCaching) shared across user languages, and tool
 * descriptions readable for the LLM's routing decision. Only the
 * RESPONSE language flips, via this one-line directive at the end.
 *
 * Per Anthropic's multilingual-support guidance: "explicitly stating
 * the desired output language improves reliability."
 *
 * Reads `App::getLocale()`, so callers (queue workers, scheduled
 * commands) MUST set the locale before dispatching the agent:
 *
 *     App::setLocale($user->preferredLocale());
 *     $agent->prompt(...);
 */
class LanguageDirective
{
    /**
     * Returns the directive to append to system-prompt text, including
     * the leading blank line. Returns an empty string for English
     * (and any unknown locale — fail safe, default behaviour).
     */
    public static function current(): string
    {
        return self::for(App::getLocale());
    }

    public static function for(string $locale): string
    {
        return match ($locale) {
            'nl' => "\n\n## Response language\n"
                .'Respond to the runner in Dutch (Nederlands). Use idiomatic, '
                .'native-coach phrasing — not literal English translations. '
                .'Keep proper nouns, acronyms, and running terms in their '
                ."original form when that's how Dutch runners actually use "
                .'them: HR, VO2max, km, 5k, 10k, PR, threshold, tempo, '
                .'intervals, fartlek. Race distances and pace values stay '
                .'in numbers (4:30/km, 21,1 km — note Dutch decimal comma).',
            default => '',
        };
    }
}
