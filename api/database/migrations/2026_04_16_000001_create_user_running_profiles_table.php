<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_running_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->timestamp('analyzed_at')->nullable();
            $table->date('data_start_date')->nullable();
            $table->date('data_end_date')->nullable();
            $table->json('metrics')->nullable();
            $table->text('narrative_summary')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_running_profiles');
    }
};
