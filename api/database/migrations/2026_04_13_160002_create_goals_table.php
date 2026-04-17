<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type')->default('race'); // race | general_fitness | pr_attempt
            $table->string('name');
            $table->string('distance')->nullable(); // 5k | 10k | half_marathon | marathon | custom
            $table->unsignedInteger('custom_distance_meters')->nullable();
            $table->unsignedInteger('goal_time_seconds')->nullable();
            $table->date('target_date')->nullable();
            $table->string('status')->default('planning');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
