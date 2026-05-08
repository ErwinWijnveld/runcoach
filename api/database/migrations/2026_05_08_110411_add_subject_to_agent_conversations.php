<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/*
 * Forward-fix for prod (Laravel Cloud / Postgres). The base migration
 * `create_agent_conversations_table` was edited in-place to add
 * subject_type/subject_id, but prod runs `migrate --force` (never
 * re-runs an existing migration), so the columns are missing there.
 * Locally they already exist via migrate:fresh — this migration is
 * idempotent so both paths converge.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('agent_conversations', function (Blueprint $table) {
            if (! Schema::hasColumn('agent_conversations', 'subject_type')) {
                $table->string('subject_type')->nullable()->after('context');
            }
            if (! Schema::hasColumn('agent_conversations', 'subject_id')) {
                $table->unsignedBigInteger('subject_id')->nullable()->after('subject_type');
            }
        });

        $indexName = 'agent_conversations_user_id_subject_type_subject_id_index';
        $exists = collect(Schema::getIndexes('agent_conversations'))
            ->contains(fn ($idx) => ($idx['name'] ?? null) === $indexName);

        if (! $exists) {
            Schema::table('agent_conversations', function (Blueprint $table) {
                $table->index(['user_id', 'subject_type', 'subject_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::table('agent_conversations', function (Blueprint $table) {
            if (Schema::hasColumn('agent_conversations', 'subject_id')) {
                $table->dropColumn('subject_id');
            }
            if (Schema::hasColumn('agent_conversations', 'subject_type')) {
                $table->dropColumn('subject_type');
            }
        });
    }
};
