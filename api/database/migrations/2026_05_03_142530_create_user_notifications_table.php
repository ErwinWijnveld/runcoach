<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // Type discriminator. Future: profile_completion, race_check_in, ...
            $table->string('type');
            $table->string('title');
            $table->text('body');
            // Type-specific payload. For pace_adjustment:
            // {source_training_result_id, training_type, pace_factor}
            $table->json('action_data')->nullable();
            // pending → user must act; accepted/dismissed → no longer in inbox.
            $table->string('status')->default('pending');
            $table->timestamp('acted_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_notifications');
    }
};
