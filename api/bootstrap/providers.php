<?php

use App\Providers\AppServiceProvider;
use App\Providers\Filament\AdminPanelProvider;
use App\Providers\Filament\CoachPanelProvider;

return [
    AppServiceProvider::class,
    AdminPanelProvider::class,
    CoachPanelProvider::class,
];
