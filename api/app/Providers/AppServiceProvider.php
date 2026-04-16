<?php

namespace App\Providers;

use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;
use Laravel\Ai\Events\InvokingTool;
use Laravel\Ai\Events\ToolInvoked;

class AppServiceProvider extends ServiceProvider
{
    private const TOOL_LOG_MAX_OUTPUT = 800;

    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        if ($this->app->environment('local')) {
            $this->logAgentToolInvocations();
        }
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
