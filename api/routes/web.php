<?php

use App\Http\Controllers\InviteController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/invites/{token}', [InviteController::class, 'landing'])->name('invites.landing');
