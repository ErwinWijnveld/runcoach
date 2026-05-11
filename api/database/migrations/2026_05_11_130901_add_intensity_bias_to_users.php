<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'intensity_bias')) {
                $table->string('intensity_bias', 16)
                    ->default('standard')
                    ->after('coach_style');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'intensity_bias')) {
                $table->dropColumn('intensity_bias');
            }
        });
    }
};
