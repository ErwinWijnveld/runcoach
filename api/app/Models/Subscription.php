<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'rc_app_user_id',
    'rc_original_app_user_id',
    'product_id',
    'store',
    'status',
    'period_type',
    'purchased_at',
    'expires_at',
    'cancelled_at',
    'environment',
    'raw_attributes',
])]
class Subscription extends Model
{
    public const STATUS_ACTIVE = 'active';

    public const STATUS_IN_GRACE_PERIOD = 'in_grace_period';

    public const STATUS_IN_BILLING_RETRY = 'in_billing_retry';

    public const STATUS_EXPIRED = 'expired';

    public const STATUS_CANCELLED = 'cancelled';

    public const STATUS_PAUSED = 'paused';

    public const STORE_APP_STORE = 'app_store';

    public const STORE_PLAY_STORE = 'play_store';

    public const STORE_STRIPE = 'stripe';

    public const STORE_COMP = 'comp';

    /**
     * Granted from a client-side entitlement claim in LOCAL env only — used to
     * make RevenueCat Test Store purchases unlock the server-side gate during
     * local dev, where there's no working REST API / webhook to verify
     * against. Never written in production (see SubscriptionsController::sync).
     */
    public const STORE_TEST = 'test_store';

    protected function casts(): array
    {
        return [
            'purchased_at' => 'datetime',
            'expires_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'raw_attributes' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
