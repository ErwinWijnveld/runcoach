<?php

namespace App\Filament\Widgets;

use App\Models\TokenUsage;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class TokenUsageOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        $today = (int) TokenUsage::whereDate('created_at', today())->sum('total_tokens');
        $thisWeek = (int) TokenUsage::where('created_at', '>=', now()->startOfWeek())->sum('total_tokens');
        $all = (int) TokenUsage::sum('total_tokens');
        $userCount = TokenUsage::whereNotNull('user_id')
            ->where('created_at', '>=', now()->startOfWeek())
            ->distinct('user_id')
            ->count('user_id');

        return [
            Stat::make('Tokens today', number_format($today)),
            Stat::make('Tokens this week', number_format($thisWeek))
                ->description("{$userCount} active users")
                ->descriptionColor('gray'),
            Stat::make('Tokens all-time', number_format($all)),
        ];
    }
}
