<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'invocation_id',
    'user_id',
    'conversation_id',
    'agent_class',
    'context',
    'provider',
    'model',
    'prompt_tokens',
    'completion_tokens',
    'cache_write_input_tokens',
    'cache_read_input_tokens',
    'reasoning_tokens',
    'total_tokens',
])]
class TokenUsage extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
