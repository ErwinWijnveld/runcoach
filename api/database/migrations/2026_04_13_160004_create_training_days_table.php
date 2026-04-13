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
        Schema::create('training_days', function (Blueprint $table) {
            $table->id();
            $table->foreignId('training_week_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->string('type');
            $table->string('title');
            $table->string('description')->nullable();
            $table->decimal('target_km', 5, 1)->nullable();
            $table->unsignedInteger('target_pace_seconds_per_km')->nullable();
            $table->unsignedTinyInteger('target_heart_rate_zone')->nullable();
            $table->json('intervals_json')->nullable();
            $table->unsignedTinyInteger('order');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('training_days');
    }
};
