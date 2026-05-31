<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plan_evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('goal_id')->constrained()->cascadeOnDelete();
            $table->foreignId('training_week_id')->nullable()->constrained()->nullOnDelete();
            // Sunday of the evaluation window. Cron picks rows whose date has passed.
            $table->date('scheduled_for');
            // pending → due in the future / not yet run
            // processing → cron picked it up, agent running
            // ready → AI produced a report + proposal awaiting accept
            // no_change_needed → AI produced a report, no plan changes needed
            // accepted / dismissed → terminal states
            $table->string('status')->default('pending');
            $table->text('report_markdown')->nullable();
            $table->foreignId('proposal_id')->nullable()->constrained('coach_proposals')->nullOnDelete();
            $table->foreignId('notification_id')->nullable()->constrained('user_notifications')->nullOnDelete();
            $table->timestamp('triggered_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status', 'scheduled_for']);
            $table->index(['scheduled_for', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plan_evaluations');
    }
};
