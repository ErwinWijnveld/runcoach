<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('revenuecat_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_id');
            $table->string('event_type');
            $table->string('app_user_id')->nullable();
            $table->json('payload');
            $table->timestamp('processed_at')->nullable();
            $table->text('error')->nullable();
            $table->timestamp('received_at');
            $table->timestamps();

            $table->unique('event_id');
            $table->index('app_user_id');
            $table->index('processed_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('revenuecat_webhook_events');
    }
};
