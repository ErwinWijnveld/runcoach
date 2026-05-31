<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'event_id',
    'event_type',
    'app_user_id',
    'payload',
    'processed_at',
    'error',
    'received_at',
])]
class RevenueCatWebhookEvent extends Model
{
    protected $table = 'revenuecat_webhook_events';

    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'processed_at' => 'datetime',
            'received_at' => 'datetime',
        ];
    }
}
