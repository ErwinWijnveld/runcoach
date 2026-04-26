<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organization_memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('role');
            $table->string('status');
            $table->foreignId('coach_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('invited_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('invite_token')->nullable()->unique();
            $table->string('invite_email')->nullable();
            $table->timestamp('invited_at')->nullable();
            $table->timestamp('requested_at')->nullable();
            $table->timestamp('joined_at')->nullable();
            $table->timestamp('removed_at')->nullable();
            $table->timestamps();

            $table->index(['organization_id', 'role', 'status']);
            $table->index(['user_id', 'status']);
            $table->index('coach_user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('organization_memberships');
    }
};
