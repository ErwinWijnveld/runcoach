<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'apple' => [
        // Bundle id of the iOS app — must match the `aud` claim on every
        // Sign-in-with-Apple identity token issued for this app. Defaults to
        // the production bundle id; tests override with services.apple.bundle_id.
        'bundle_id' => env('APPLE_BUNDLE_ID', 'com.erwinwijnveld.runcoach'),
    ],

    'revenuecat' => [
        // Shared secret pasted into the RC dashboard webhook config and matched
        // against the Authorization header on every incoming webhook request.
        'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
        // v2 secret REST API key for server-side entitlement fetches (used by
        // the /subscriptions/sync endpoint as defense-in-depth against webhook
        // delays/loss). Never exposed to the client.
        'rest_api_key' => env('REVENUECAT_REST_API_KEY'),
        // RC project id (NOT the public SDK key — that lives in the Flutter app).
        'project_id' => env('REVENUECAT_PROJECT_ID'),
    ],

];
