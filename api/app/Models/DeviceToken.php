<?php

namespace App\Models;

use Database\Factories\DeviceTokenFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'token',
    'platform',
    'app_version',
    'last_seen_at',
])]
class DeviceToken extends Model
{
    /** @use HasFactory<DeviceTokenFactory> */
    use HasFactory;

    public const PLATFORM_IOS = 'ios';

    public const PLATFORM_ANDROID = 'android';

    protected function casts(): array
    {
        return [
            'last_seen_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
