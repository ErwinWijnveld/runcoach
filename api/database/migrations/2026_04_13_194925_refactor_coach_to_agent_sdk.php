<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('coach_proposals', function (Blueprint $table) {
            $table->dropForeign(['coach_message_id']);
            $table->dropColumn('coach_message_id');
            $table->string('agent_message_id', 36)->nullable()->after('id');
            $table->foreignId('user_id')->nullable()->after('agent_message_id')->constrained()->cascadeOnDelete();
        });

        Schema::dropIfExists('coach_messages');
        Schema::dropIfExists('coach_conversations');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::create('coach_conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('race_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->timestamps();
        });

        Schema::create('coach_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_conversation_id')->constrained()->cascadeOnDelete();
            $table->string('role');
            $table->text('content');
            $table->json('context_snapshot')->nullable();
            $table->timestamps();
        });

        Schema::table('coach_proposals', function (Blueprint $table) {
            $table->dropColumn(['agent_message_id', 'user_id']);
            $table->foreignId('coach_message_id')->nullable()->constrained()->cascadeOnDelete();
        });
    }
};
