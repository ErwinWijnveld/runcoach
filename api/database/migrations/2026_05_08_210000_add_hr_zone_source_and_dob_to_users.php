<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Forward migration for the HR-zone auto-derivation feature
 * (`docs/superpowers/specs/2026-05-08-hr-zones-auto-derive.md`).
 *
 * The first iteration of this feature edited the baseline users
 * migration in place — fine for local-only dev, but production has
 * already shipped the original schema, and Laravel Cloud's `migrate
 * --force` is forward-only. This migration brings prod up to date.
 *
 * Idempotent column checks keep it safe to run on:
 *   - fresh local DBs (the baseline doesn't have these columns now)
 *   - existing prod (real users have neither column),
 *   - dev DBs that briefly had them via the old in-place edit (re-run
 *     after `migrate:fresh` becomes a no-op for the columns it skips).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'heart_rate_zones_source')) {
                // How `heart_rate_zones` was populated — see
                // App\Enums\HeartRateZonesSource. 'manual' is sticky
                // against scheduled re-derives but explicit
                // user-triggered recompute overwrites it.
                $table->string('heart_rate_zones_source', 32)
                    ->default('default')
                    ->after('heart_rate_zones');
            }

            if (! Schema::hasColumn('users', 'date_of_birth')) {
                // Manually-entered DOB. Used by the HR-zone deriver as a
                // fallback when HealthKit can't surface dateOfBirth, and
                // by the yearly birthday push (`SendBirthdayZoneReminders`).
                $table->date('date_of_birth')
                    ->nullable()
                    ->after('heart_rate_zones_source');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'date_of_birth')) {
                $table->dropColumn('date_of_birth');
            }
            if (Schema::hasColumn('users', 'heart_rate_zones_source')) {
                $table->dropColumn('heart_rate_zones_source');
            }
        });
    }
};
