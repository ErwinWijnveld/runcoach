<?php

namespace App\Console\Commands\Subscriptions;

use App\Models\Subscription;
use App\Services\Subscription\EntitlementSyncService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

#[Signature('subscriptions:reconcile')]
#[Description('Daily safety net: expire any subscription past grace whose EXPIRATION webhook was lost. Logs a warning for unusually-overdue rows (>7d past expires_at) so a human can investigate the webhook path.')]
class ReconcileSubscriptions extends Command
{
    public function handle(EntitlementSyncService $sync): int
    {
        $expiredCount = 0;
        $forensicCount = 0;

        Subscription::query()
            ->whereNotIn('status', [Subscription::STATUS_EXPIRED, Subscription::STATUS_CANCELLED])
            ->where('store', '!=', Subscription::STORE_COMP)
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now()->subDay())
            ->with('user')
            ->chunkById(100, function ($subs) use ($sync, &$expiredCount, &$forensicCount) {
                foreach ($subs as $sub) {
                    // Flag the unusually-overdue ones as a webhook-path smell.
                    // Step 1 below will still auto-fix them — this is purely
                    // a forensic signal for ops.
                    if ($sub->expires_at !== null && $sub->expires_at->lt(now()->subDays(7))) {
                        Log::warning('[rc:reconcile] overdue subscription auto-expired by reconciler', [
                            'subscription_id' => $sub->id,
                            'user_id' => $sub->user_id,
                            'expires_at' => $sub->expires_at->toIso8601String(),
                        ]);
                        $forensicCount++;
                    }

                    if ($sub->user !== null) {
                        $sync->expire($sub->user);
                    } else {
                        $sub->update(['status' => Subscription::STATUS_EXPIRED]);
                    }
                    $expiredCount++;
                }
            });

        $this->info("Expired: {$expiredCount}, Overdue (>7d) flagged: {$forensicCount}");

        return self::SUCCESS;
    }
}
