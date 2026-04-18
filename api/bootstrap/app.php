<?php

ini_set('memory_limit', '512M');
// CLI (queue workers, artisan serve, plan generation via dev server) gets
// no limit; web requests cap at 300s — the onboarding plan generator
// can take up to ~90s on a slow Anthropic day.
ini_set('max_execution_time', PHP_SAPI === 'cli' ? '0' : '300');

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
