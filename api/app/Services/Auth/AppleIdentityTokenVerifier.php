<?php

namespace App\Services\Auth;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use UnexpectedValueException;

/**
 * Verifies an Apple "Sign in with Apple" identity token (JWT).
 *
 * The native iOS dialog hands the Flutter app an `identityToken` JWT signed
 * by Apple with RS256. We validate signature against Apple's published JWKS,
 * issuer (`https://appleid.apple.com`), audience (our bundle id), and
 * expiry — then trust the `sub` claim as the stable user id.
 *
 * Apple does not support refresh on identity tokens; the app re-acquires one
 * on every sign-in. Server-side we never store the token, only the `sub`.
 */
class AppleIdentityTokenVerifier
{
    private const JWKS_URL = 'https://appleid.apple.com/auth/keys';

    private const ISSUER = 'https://appleid.apple.com';

    private const JWKS_CACHE_TTL_SECONDS = 3600;

    /**
     * @return array{sub: string, email: string|null, email_verified: bool}
     */
    public function verify(string $identityToken): array
    {
        $expectedAudience = config('services.apple.bundle_id');

        if (! is_string($expectedAudience) || $expectedAudience === '') {
            throw new \LogicException('services.apple.bundle_id is not configured.');
        }

        $keys = $this->loadJwks();

        try {
            $payload = (array) JWT::decode($identityToken, $keys);
        } catch (\Throwable $e) {
            throw new InvalidAppleIdentityTokenException(
                'Apple identity token failed signature/expiry validation.',
                previous: $e,
            );
        }

        if (($payload['iss'] ?? null) !== self::ISSUER) {
            throw new InvalidAppleIdentityTokenException('Wrong issuer in Apple identity token.');
        }

        if (($payload['aud'] ?? null) !== $expectedAudience) {
            throw new InvalidAppleIdentityTokenException('Apple identity token audience does not match this app.');
        }

        $sub = $payload['sub'] ?? null;
        if (! is_string($sub) || $sub === '') {
            throw new InvalidAppleIdentityTokenException('Apple identity token has no sub claim.');
        }

        $email = $payload['email'] ?? null;
        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOL);

        return [
            'sub' => $sub,
            'email' => is_string($email) && $email !== '' ? $email : null,
            'email_verified' => $emailVerified,
        ];
    }

    /**
     * @return array<string, Key>
     */
    private function loadJwks(): array
    {
        $jwks = Cache::remember(
            'apple:jwks',
            self::JWKS_CACHE_TTL_SECONDS,
            fn () => Http::get(self::JWKS_URL)->throw()->json(),
        );

        if (! is_array($jwks) || ! isset($jwks['keys']) || ! is_array($jwks['keys'])) {
            throw new UnexpectedValueException('Apple JWKS response is malformed.');
        }

        return JWK::parseKeySet($jwks);
    }
}
