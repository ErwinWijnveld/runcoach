<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gate AI-spending HTTP routes behind an active Pro entitlement.
 *
 * 402 Payment Required (semantically correct, distinct from 401/403) so the
 * Flutter app can route the user back to the paywall on this exact status.
 */
class RequireProEntitlement
{
    /**
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user === null || ! $user->isPro()) {
            return response()->json([
                'error' => 'pro_required',
                'message' => 'A RunCoach Pro subscription is required.',
            ], 402);
        }

        return $next($request);
    }
}
