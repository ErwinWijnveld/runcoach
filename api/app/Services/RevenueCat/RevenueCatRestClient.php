<?php

namespace App\Services\RevenueCat;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Thin client for RevenueCat's REST API. Used by the sync endpoint as
 * defense-in-depth against webhook delivery delays — the source of truth on
 * cold start is what RC's REST API reports, not what the client sends.
 *
 * Auth is the secret REST API key from RC dashboard → Project settings → API
 * keys (NOT the public iOS SDK key, which lives in the Flutter app).
 *
 * Tests bind a fake via the container or use `Http::fake()` against
 * `api.revenuecat.com`.
 */
class RevenueCatRestClient
{
    private const BASE_URL = 'https://api.revenuecat.com';

    private const TIMEOUT_SECONDS = 5;

    public function __construct(
        private readonly ?string $restApiKey = null,
        private readonly ?string $projectId = null,
    ) {}

    /**
     * Fetch the active entitlements payload for one app user.
     *
     * Endpoint shape (v2):
     *   GET /v2/projects/{project_id}/customers/{app_user_id}/active_entitlements
     *
     * @return array<string, mixed> the decoded `items[]` keyed by `lookup_key` (the entitlement id, e.g. `pro`)
     *
     * @throws RuntimeException on missing config or non-2xx response
     */
    public function getActiveEntitlements(string $appUserId): array
    {
        $key = $this->restApiKey ?? (string) config('services.revenuecat.rest_api_key');
        $project = $this->projectId ?? (string) config('services.revenuecat.project_id');

        if ($key === '' || $project === '') {
            throw new RuntimeException('RevenueCat REST credentials are not configured.');
        }

        $url = sprintf(
            '%s/v2/projects/%s/customers/%s/active_entitlements',
            self::BASE_URL,
            urlencode($project),
            urlencode($appUserId),
        );

        $response = Http::withToken($key)
            ->acceptJson()
            ->timeout(self::TIMEOUT_SECONDS)
            ->get($url);

        return $this->parseEntitlements($response);
    }

    /**
     * Normalize RC's v2 active-entitlements response into a `{lookup_key => row}`
     * map so callers can do `$result['pro'] ?? null` without traversing `items[]`.
     *
     * @return array<string, mixed>
     */
    private function parseEntitlements(Response $response): array
    {
        if ($response->status() === 404) {
            // RC returns 404 for unknown app_user_id — treat as "no entitlements".
            return [];
        }

        if (! $response->successful()) {
            throw new RuntimeException(sprintf(
                'RevenueCat REST returned %d: %s',
                $response->status(),
                substr((string) $response->body(), 0, 500),
            ));
        }

        $json = $response->json();
        $items = is_array($json) ? ($json['items'] ?? []) : [];
        $out = [];
        foreach ($items as $item) {
            if (! is_array($item)) {
                continue;
            }
            $key = $item['lookup_key'] ?? null;
            if (is_string($key) && $key !== '') {
                $out[$key] = $item;
            }
        }

        return $out;
    }
}
