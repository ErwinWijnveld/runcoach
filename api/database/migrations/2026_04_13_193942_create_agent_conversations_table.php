<?php

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Laravel\Ai\Migrations\AiMigration;

return new class extends AiMigration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('agent_conversations', function (Blueprint $table) {
            $table->string('id', 36)->primary();
            $table->foreignId('user_id')->nullable();
            $table->string('title');
            $table->string('context')->nullable()->index();
            // Polymorphic owner: when set, this conversation is scoped to a
            // specific subject (e.g. a TrainingDay for the workout-agent
            // chat) and is hidden from the general coach chat list. Today
            // the only subject_type is 'training_day'.
            $table->string('subject_type')->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'updated_at']);
            $table->index(['user_id', 'subject_type', 'subject_id']);
        });

        Schema::create('agent_conversation_messages', function (Blueprint $table) {
            $table->string('id', 36)->primary();
            $table->string('conversation_id', 36)->index();
            $table->foreignId('user_id')->nullable();
            $table->string('agent');
            $table->string('role', 25);
            // Upgraded from TEXT (64KB) to LONGTEXT (4GB) — a single
            // CreateSchedule call for a 24-week plan already emits ~25KB
            // of tool_results, and after JSON escaping + multiple tool
            // invocations in one turn we hit the TEXT limit.
            $table->longText('content');
            $table->text('attachments');
            $table->longText('tool_calls');
            $table->longText('tool_results');
            $table->text('usage');
            $table->text('meta');
            $table->timestamps();

            $table->index(['conversation_id', 'user_id', 'updated_at'], 'conversation_index');
            $table->index(['user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('agent_conversations');
        Schema::dropIfExists('agent_conversation_messages');
    }
};
