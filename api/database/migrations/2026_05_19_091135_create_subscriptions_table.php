<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('rc_app_user_id');
            $table->string('rc_original_app_user_id')->nullable();
            $table->string('product_id');
            $table->string('store');
            $table->string('status');
            $table->string('period_type');
            $table->timestamp('purchased_at');
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->string('environment');
            $table->json('raw_attributes')->nullable();
            $table->timestamps();

            $table->unique('user_id');
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
