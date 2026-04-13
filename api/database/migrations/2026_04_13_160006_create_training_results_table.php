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
        Schema::create('training_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('training_day_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('strava_activity_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('compliance_score', 3, 1);
            $table->decimal('actual_km', 5, 1);
            $table->unsignedInteger('actual_pace_seconds_per_km');
            $table->decimal('actual_avg_heart_rate', 5, 1)->nullable();
            $table->decimal('pace_score', 3, 1);
            $table->decimal('distance_score', 3, 1);
            $table->decimal('heart_rate_score', 3, 1)->nullable();
            $table->text('ai_feedback')->nullable();
            $table->timestamp('matched_at');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('training_results');
    }
};
