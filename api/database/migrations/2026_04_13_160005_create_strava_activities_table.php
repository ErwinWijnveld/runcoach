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
        Schema::create('strava_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->bigInteger('strava_id')->unique();
            $table->string('type');
            $table->string('name');
            $table->unsignedInteger('distance_meters');
            $table->unsignedInteger('moving_time_seconds');
            $table->unsignedInteger('elapsed_time_seconds');
            $table->decimal('average_heartrate', 5, 1)->nullable();
            $table->decimal('average_speed', 5, 2);
            $table->timestamp('start_date');
            $table->text('summary_polyline')->nullable();
            $table->json('raw_data');
            $table->timestamp('synced_at');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('strava_activities');
    }
};
