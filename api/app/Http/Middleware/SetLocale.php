<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class SetLocale
{
    public const SUPPORTED = ['en', 'nl'];

    /**
     * Resolve the locale for the request and set it on App + Carbon so
     * __() and date formatting both honour it.
     *
     * Priority: authenticated user.locale > Accept-Language header > fallback.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $locale = $this->resolve($request);

        App::setLocale($locale);
        Carbon::setLocale($locale);

        return $next($request);
    }

    private function resolve(Request $request): string
    {
        $user = $request->user();
        if ($user?->locale && in_array($user->locale, self::SUPPORTED, true)) {
            return $user->locale;
        }

        return $request->getPreferredLanguage(self::SUPPORTED)
            ?? config('app.fallback_locale', 'en');
    }
}
