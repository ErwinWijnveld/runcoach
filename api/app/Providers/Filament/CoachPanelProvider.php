<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages\Dashboard;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets\AccountWidget;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\PreventRequestForgery;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class CoachPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->id('coach')
            ->path('coach')
            ->brandName('RunCoach for Coaches')
            ->login()
            ->darkMode(false)
            ->viteTheme('resources/css/filament/coach/theme.css')
            ->font('Space Grotesk')
            ->colors([
                'primary' => Color::hex('#E9B638'),
                'gray' => Color::hex('#8B7355'),
                'success' => Color::hex('#34C759'),
                'danger' => Color::hex('#8F3A3A'),
                'warning' => Color::hex('#E9B638'),
            ])
            ->discoverResources(in: app_path('Filament/Coach/Resources'), for: 'App\Filament\Coach\Resources')
            ->discoverPages(in: app_path('Filament/Coach/Pages'), for: 'App\Filament\Coach\Pages')
            ->pages([
                Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Coach/Widgets'), for: 'App\Filament\Coach\Widgets')
            ->widgets([
                AccountWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                PreventRequestForgery::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
