<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserRunningProfile extends Model
{
    protected $fillable = [
        'user_id', 'analyzed_at',
        'data_start_date', 'data_end_date',
        'metrics', 'narrative_summary',
    ];

    protected $casts = [
        'analyzed_at' => 'datetime',
        'data_start_date' => 'date',
        'data_end_date' => 'date',
        'metrics' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
