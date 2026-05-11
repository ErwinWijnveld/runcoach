<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Forward migration for the onboarding self-reported baseline stats
 * feature (`docs/superpowers/specs/2026-05-11-onboarding-self-reported-stats-design.md`).
 *
 * Three nullable columns on `users` store the runner's hand-entered
 * baseline volume + easy pace. Null = use cascade. Idempotent guards so
 * this is safe to re-run on dev DBs that may already have the columns.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'self_reported_weekly_km')) {
                $table->decimal('self_reported_weekly_km', 5, 1)
                    ->nullable()
                    ->after('date_of_birth');
            }

            if (! Schema::hasColumn('users', 'self_reported_easy_pace_seconds_per_km')) {
                $table->unsignedSmallInteger('self_reported_easy_pace_seconds_per_km')
                    ->nullable()
                    ->after('self_reported_weekly_km');
            }

            if (! Schema::hasColumn('users', 'self_reported_stats_at')) {
                $table->timestamp('self_reported_stats_at')
                    ->nullable()
                    ->after('self_reported_easy_pace_seconds_per_km');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'self_reported_stats_at')) {
                $table->dropColumn('self_reported_stats_at');
            }
            if (Schema::hasColumn('users', 'self_reported_easy_pace_seconds_per_km')) {
                $table->dropColumn('self_reported_easy_pace_seconds_per_km');
            }
            if (Schema::hasColumn('users', 'self_reported_weekly_km')) {
                $table->dropColumn('self_reported_weekly_km');
            }
        });
    }
};
