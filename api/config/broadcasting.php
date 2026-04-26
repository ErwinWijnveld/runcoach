<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Broadcaster
    |--------------------------------------------------------------------------
    |
    | Supported: "reverb", "pusher", "ably", "redis", "log", "null"
    |
    */

    'default' => env('BROADCAST_CONNECTION', 'null'),

    /*
    |--------------------------------------------------------------------------
    | Broadcast Connections
    |--------------------------------------------------------------------------
    */

    'connections' => [

        'reverb' => [
            'driver' => 'reverb',
            'key' => env('REVERB_APP_KEY'),
            'secret' => env('REVERB_APP_SECRET'),
            'app_id' => env('REVERB_APP_ID'),
            'options' => [
                'host' => env('REVERB_HOST'),
                'port' => env('REVERB_PORT', 443),
                'scheme' => env('REVERB_SCHEME', 'https'),
                'useTLS' => env('REVERB_SCHEME', 'https') === 'https',
            ],
            'client_options' => [],
        ],

        'log' => [
            'driver' => 'log',
        ],

        'null' => [
            'driver' => 'null',
        ],

        // APNs auth-token credentials consumed by laravel-notification-channels/apn.
        // The package reads this exact path: broadcasting.connections.apn.
        // For local + TestFlight, set APN_PRODUCTION=false (sandbox APNs server).
        // Production builds should set APN_PRODUCTION=true.
        // APN_PRIVATE_KEY_PATH is resolved relative to the project root so
        // queue workers find the .p8 regardless of their working directory.
        'apn' => [
            'key_id' => env('APN_KEY_ID'),
            'team_id' => env('APN_TEAM_ID'),
            'app_bundle_id' => env('APN_BUNDLE_ID', env('APPLE_BUNDLE_ID', 'com.erwinwijnveld.runcoach')),
            'private_key_path' => base_path(env('APN_PRIVATE_KEY_PATH', 'storage/app/apns/AuthKey.p8')),
            'private_key_secret' => env('APN_PRIVATE_KEY_SECRET'),
            'production' => env('APN_PRODUCTION', false),
        ],

    ],

];
