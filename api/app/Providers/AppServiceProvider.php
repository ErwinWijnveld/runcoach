<?php

namespace App\Providers;

use App\Ai\Support\AnthropicPromptCaching;
use App\Ai\Support\AnthropicToolInputSanitizer;
use GuzzleHttp\Psr7\Utils;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;
use Laravel\Ai\Events\InvokingTool;
use Laravel\Ai\Events\ToolInvoked;
use Psr\Http\Message\ResponseInterface;

class AppServiceProvider extends ServiceProvider
{
    private const TOOL_LOG_MAX_OUTPUT = 800;

    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Http::globalRequestMiddleware(new AnthropicToolInputSanitizer);
        Http::globalRequestMiddleware(new AnthropicPromptCaching);

        if ($this->app->environment('local')) {
            $this->logAgentToolInvocations();
            $this->logAnthropicHttpErrors();
        }
    }

    /**
     * In local, dump the Anthropic response body on any non-2xx.
     * RequestException only includes the status line — the actual
     * error message lives in the body.
     */
    private function logAnthropicHttpErrors(): void
    {
        Http::globalResponseMiddleware(function (ResponseInterface $response) {
            if ($response->getStatusCode() < 400) {
                return $response;
            }

            $body = $response->getBody();
            $content = (string) $body;

            if ($body->isSeekable()) {
                $body->rewind();
                $finalBody = $body;
            } else {
                $finalBody = Utils::streamFor($content);
                $response = $response->withBody($finalBody);
            }

            if (str_contains($content, '"type":"error"') || str_contains($content, 'anthropic')) {
                Log::warning('[anthropic:'.$response->getStatusCode().'] '.substr($content, 0, 4000));
            }

            return $response;
        });
    }

    private function logAgentToolInvocations(): void
    {
        $starts = [];

        Event::listen(function (InvokingTool $event) use (&$starts) {
            $name = class_basename($event->tool);
            $args = json_encode($event->arguments, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
            $starts[$event->toolInvocationId] = microtime(true);
            Log::info("[agent:tool] → {$name} input={$args}");
        });

        Event::listen(function (ToolInvoked $event) use (&$starts) {
            $name = class_basename($event->tool);
            $start = $starts[$event->toolInvocationId] ?? microtime(true);
            unset($starts[$event->toolInvocationId]);
            $ms = (int) round((microtime(true) - $start) * 1000);

            $output = is_string($event->result) ? $event->result : json_encode($event->result);
            $truncated = strlen($output) > self::TOOL_LOG_MAX_OUTPUT
                ? substr($output, 0, self::TOOL_LOG_MAX_OUTPUT).'…('.strlen($output).'b)'
                : $output;

            Log::info("[agent:tool] ← {$name} ({$ms}ms) output={$truncated}");
        });
    }
}
