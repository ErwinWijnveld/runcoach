<?php

namespace App\Http\Controllers\Webhooks;

use App\Http\Controllers\Controller;
use App\Jobs\Subscription\ProcessRevenueCatWebhookEvent;
use App\Models\RevenueCatWebhookEvent;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

class RevenueCatWebhookController extends Controller
{
    /**
     * Receive a RevenueCat webhook delivery.
     *
     * Auth is via a shared secret pasted into the RC dashboard webhook config,
     * matched against the Authorization header here. The endpoint never performs
     * synchronous state writes — it inserts the event row for idempotency and
     * dispatches a queued job, returning 200 fast so RC doesn't retry.
     */
    public function __invoke(Request $request): Response
    {
        $expected = (string) config('services.revenuecat.webhook_secret');
        $provided = (string) $request->header('Authorization', '');

        if ($expected === '' || ! hash_equals($expected, $provided)) {
            Log::warning('[rc:webhook] bad auth header', [
                'ip' => $request->ip(),
            ]);

            return response('', 401);
        }

        $event = $request->input('event');
        if (! is_array($event) || empty($event['id']) || empty($event['type'])) {
            return response('', 422);
        }

        try {
            $row = RevenueCatWebhookEvent::create([
                'event_id' => $event['id'],
                'event_type' => $event['type'],
                'app_user_id' => $event['app_user_id'] ?? null,
                'payload' => $request->all(),
                'received_at' => now(),
            ]);
        } catch (UniqueConstraintViolationException) {
            Log::info('[rc:webhook] duplicate event_id, skipping', [
                'event_id' => $event['id'],
            ]);

            return response('', 200);
        }

        ProcessRevenueCatWebhookEvent::dispatch($row->id);

        return response('', 200);
    }
}
