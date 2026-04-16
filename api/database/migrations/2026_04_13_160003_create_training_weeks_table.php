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
        Schema::create('training_weeks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('goal_id')->constrained('goals')->cascadeOnDelete();
            $table->unsignedInteger('week_number');
            $table->date('starts_at');
            $table->decimal('total_km', 6, 1);
            $table->string('focus');
            $table->text('coach_notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('training_weeks');
    }
};
