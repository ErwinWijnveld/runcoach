<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Forward-fix for prod: `training_results.pace_score` was made
 * nullable in the original create-table migration via in-place edit
 * (commit 2022401, "features"), to support interval days where the
 * full-run avg pace can't be scored against per-segment work pace.
 * `migrate --force` on Laravel Cloud doesn't re-run completed
 * migrations, so prod still has the NOT NULL constraint and any
 * interval-day match fails with `23502` when ComplianceScoringService
 * tries to insert a null pace_score.
 *
 * Idempotent: re-declaring nullable() on an already-nullable column
 * is a no-op on Laravel 11+'s native ALTER pipeline. Local DBs
 * (where migrate:fresh already produces a nullable column) safely
 * skip past this without error.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('training_results', function (Blueprint $table) {
            $table->decimal('pace_score', 3, 1)->nullable()->change();
        });
    }

    public function down(): void
    {
        // Don't reintroduce the NOT NULL — interval-day rows with null
        // pace_score may already exist in production, and re-imposing
        // the constraint would fail.
    }
};
