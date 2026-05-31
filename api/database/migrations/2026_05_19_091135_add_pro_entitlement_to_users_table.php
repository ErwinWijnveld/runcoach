<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'pro_active_until')) {
                $table->timestamp('pro_active_until')->nullable()->index();
            }
            if (! Schema::hasColumn('users', 'pro_product_id')) {
                $table->string('pro_product_id')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'pro_active_until')) {
                $table->dropIndex(['pro_active_until']);
                $table->dropColumn('pro_active_until');
            }
            if (Schema::hasColumn('users', 'pro_product_id')) {
                $table->dropColumn('pro_product_id');
            }
        });
    }
};
