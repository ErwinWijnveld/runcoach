<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RevenueCat\RevenueCatRestClient;
use App\Services\Subscription\EntitlementSyncService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class SubscriptionsController extends Controller
{
    /**
     * Resync the authenticated user's entitlement against RevenueCat's REST
     * API. Used by the Flutter app on cold-start, after every purchase, and
     * after every restore as defense-in-depth against webhook loss/delay.
     *
     * The endpoint accepts an empty body — we do NOT trust client-posted
     * `CustomerInfo`. The server pulls the truth from RC directly so a
     * malicious client can't spoof an entitlement.
     *
     * Response:
     *   { active_until: ISO8601 | null, product_id: string | null, is_pro: bool }
     *
     * On REST API failure we return 200 with the current local state so the
     * client doesn't lose a valid entitlement just because RC's status page is
     * having a bad day. Logs an error for ops visibility.
     */
    public function sync(Request $request, RevenueCatRestClient $client, EntitlementSyncService $sync): JsonResponse
    {
        $user = $request->user();

        try {
            $entitlements = $client->getActiveEntitlements((string) $user->id);
        } catch (Throwable $e) {
            // This endpoint is best-effort defense-in-depth: webhooks are the
            // primary entitlement source, and the daily reconcile job is the
            // safety net. A REST failure here (RC outage, or a misconfigured /
            // Test-Store key that has no working REST API) is non-fatal — we
            // return whatever local state we already hold. Log at warning level
            // and do NOT report(): a wrong key would otherwise spam the error
            // tracker on every app cold-start.
            Log::warning('[rc:sync] REST API call failed; returning local state', [
                'user_id' => $user->id,
                'message' => $e->getMessage(),
            ]);

            // LOCAL DEV ONLY: with RevenueCat Test Store there's no working REST
            // API to verify against, so a real purchase can never unlock the
            // server-side gate — the coach endpoints would 402 forever. In
            // local env we trust the client's CustomerInfo claim so the full
            // paywall→purchase→use-app flow is testable without an appl_ key.
            // Production NEVER reaches this (RC REST works there), and even if
            // it did, app()->environment('local') is server-controlled so a
            // production client can't spoof its way past the gate.
            $this->maybeTrustClientClaim($request, $user, $sync);

            return $this->response($user->fresh() ?? $user);
        }

        $pro = $entitlements['pro'] ?? null;

        if ($pro === null) {
            // RC reports no active 'pro' entitlement. If our local state
            // claims otherwise but the expiry is already past, clear it. Don't
            // touch state that's still in the future — a fresh webhook may be
            // mid-flight.
            if ($user->pro_active_until !== null && $user->pro_active_until->isPast()) {
                $sync->expire($user);
                $user->refresh();
            }

            return $this->response($user);
        }

        $expiresAt = $this->parseTimestamp(
            $pro['expires_date_ms'] ?? null,
            $pro['expires_date'] ?? null,
        );

        if ($expiresAt !== null && $expiresAt->isFuture()) {
            $sync->activateFromRestEntitlement($user, $pro);
            $user->refresh();
        } elseif ($user->pro_active_until !== null && $user->pro_active_until->isPast()) {
            $sync->expire($user);
            $user->refresh();
        }

        return $this->response($user);
    }

    /**
     * LOCAL-DEV ONLY. Simulate a successful purchase — grants the test
     * entitlement directly so the full post-paywall app is usable without a
     * real (Test Store or App Store) transaction. Backs the debug "Simulate
     * payment" button on the paywall screen. 404s outside local env.
     */
    public function devActivate(Request $request, EntitlementSyncService $sync): JsonResponse
    {
        abort_unless(app()->environment('local'), 404);

        $user = $request->user();
        $sync->activateFromClientClaim($user, 'runcoach_pro_yearly', now()->addYear());

        return $this->response($user->fresh() ?? $user);
    }

    /**
     * LOCAL-DEV ONLY. Revoke the entitlement so the paywall shows again on the
     * next run. Backs the debug "Reset subscription" button in the profile
     * menu. 404s outside local env.
     */
    public function devDeactivate(Request $request, EntitlementSyncService $sync): JsonResponse
    {
        abort_unless(app()->environment('local'), 404);

        $user = $request->user();
        $sync->expire($user);

        return $this->response($user->fresh() ?? $user);
    }

    /**
     * LOCAL ENV ONLY. When RC REST verification is unavailable (Test Store),
     * grant the entitlement from the client's posted CustomerInfo claim so the
     * server-side gate matches what the SDK already reports. No-op outside
     * local env or when the client doesn't claim an active entitlement.
     */
    private function maybeTrustClientClaim(Request $request, $user, EntitlementSyncService $sync): void
    {
        if (! app()->environment('local')) {
            return;
        }

        $claim = $request->input('client_entitlement');
        if (! is_array($claim) || ($claim['active'] ?? false) !== true) {
            return;
        }

        $expiresAt = isset($claim['expires_at']) && is_string($claim['expires_at'])
            ? Carbon::parse($claim['expires_at'])
            : null;
        $productId = isset($claim['product_id']) && is_string($claim['product_id'])
            ? $claim['product_id']
            : null;

        Log::info('[rc:sync] local dev — trusting client entitlement claim', [
            'user_id' => $user->id,
            'product_id' => $productId,
        ]);

        $sync->activateFromClientClaim($user, $productId, $expiresAt);
    }

    private function response($user): JsonResponse
    {
        return response()->json([
            'active_until' => $user->pro_active_until?->toIso8601String(),
            'product_id' => $user->pro_product_id,
            'is_pro' => $user->isPro(),
        ]);
    }

    private function parseTimestamp(mixed $ms, mixed $iso): ?Carbon
    {
        if (is_numeric($ms)) {
            return Carbon::createFromTimestampMs((int) $ms);
        }

        if (is_string($iso) && $iso !== '') {
            return Carbon::parse($iso);
        }

        return null;
    }
}
