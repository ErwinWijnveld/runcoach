<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wearable_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // Provider that this activity originated from. Drives ingestion
            // routing, dedup, and per-source UI affordances (icons, badges).
            $table->string('source', 32);

            // Stable identifier from the source. Strava activity id (numeric
            // string), HKWorkout uuid, Open Wearables workout uuid, etc.
            $table->string('source_activity_id');

            // Per-source identity of the recording device/app, used to dedup
            // when the same physical run is written by multiple sources
            // (e.g. Apple Watch + Nike Run Club both writing to HealthKit).
            // Strava: athlete id. HealthKit: HKSource.bundleIdentifier.
            $table->string('source_user_id')->nullable();

            $table->string('type');
            $table->string('name')->nullable();

            $table->unsignedInteger('distance_meters');
            $table->unsignedInteger('duration_seconds');
            $table->unsignedInteger('elapsed_seconds')->nullable();
            $table->unsignedInteger('average_pace_seconds_per_km');

            $table->decimal('average_heartrate', 5, 1)->nullable();
            $table->decimal('max_heartrate', 5, 1)->nullable();

            $table->integer('elevation_gain_meters')->nullable();
            $table->unsignedInteger('calories_kcal')->nullable();

            $table->timestamp('start_date');
            $table->timestamp('end_date')->nullable();

            $table->json('raw_data');
            $table->timestamp('synced_at');
            $table->timestamps();

            // Per-user uniqueness, NOT global. A global unique on
            // (source, source_activity_id) would let an attacker with a valid
            // Sanctum token overwrite another user's activity by guessing
            // their HKWorkout uuid (the ingestion controller's
            // updateOrCreate would `find` the victim's row and update its
            // user_id). Scoping to user_id closes that hole and is also
            // semantically correct — each user's HealthKit issues UUIDs
            // independently of other users'.
            $table->unique(['user_id', 'source', 'source_activity_id']);
            $table->index(['user_id', 'start_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wearable_activities');
    }
};
