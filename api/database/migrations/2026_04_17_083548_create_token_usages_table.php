<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('token_usages', function (Blueprint $table) {
            $table->id();
            $table->string('invocation_id', 36)->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('conversation_id', 36)->nullable();
            $table->string('agent_class');
            $table->string('context'); // coach | onboarding | activity_feedback | weekly_insight | plan_explanation | running_narrative | other
            $table->string('provider')->nullable();
            $table->string('model')->nullable();
            $table->unsignedInteger('prompt_tokens')->default(0);
            $table->unsignedInteger('completion_tokens')->default(0);
            $table->unsignedInteger('cache_write_input_tokens')->default(0);
            $table->unsignedInteger('cache_read_input_tokens')->default(0);
            $table->unsignedInteger('reasoning_tokens')->default(0);
            $table->unsignedInteger('total_tokens')->default(0);
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['context', 'created_at']);
            $table->index(['conversation_id', 'created_at']);
            $table->index('invocation_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('token_usages');
    }
};
