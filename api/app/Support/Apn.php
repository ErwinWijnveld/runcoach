<?php

namespace App\Support;

class Apn
{
    /**
     * Whether APNs credentials are actually available to sign a push token.
     *
     * Locally the `.p8` signing key is usually absent (it's a secret, not in
     * the repo), so attempting to send would throw inside Pushok and kill the
     * queue worker. We treat APNs as configured only when the key material is
     * really present — inline content, or a key file that exists on disk.
     */
    public static function configured(): bool
    {
        $config = config('broadcasting.connections.apn');

        if (! empty($config['private_key_content'])) {
            return true;
        }

        $path = $config['private_key_path'] ?? null;

        return is_string($path) && $path !== '' && is_file($path);
    }
}
