<x-filament-panels::page>
    @php $goal = $this->goal; @endphp
    @if ($goal === null)
        <x-filament::section>
            <p>Goal not found.</p>
        </x-filament::section>
    @else
        @php
            $totalKm = $goal->trainingWeeks->sum('total_km');
            $totalDays = $goal->trainingWeeks->sum(fn ($w) => $w->trainingDays->count());
        @endphp

        <style>
            .gs-summary {
                display: flex;
                flex-wrap: wrap;
                gap: 1.5rem;
                align-items: center;
                padding: 1rem 1.25rem;
                background: #fff;
                border: 1px solid #E5E7EB;
                border-radius: 1rem;
                margin-bottom: 1.5rem;
            }
            .dark .gs-summary { background: #111827; border-color: rgba(255,255,255,0.1); }
            .gs-summary-cell { flex: 0 1 auto; min-width: 110px; }
            .gs-summary-cell.grow { flex: 1 1 200px; }
            .gs-label { font-size: 0.7rem; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; color: #6B7280; }
            .gs-value { font-size: 1rem; font-weight: 600; color: #111827; margin-top: 2px; }
            .dark .gs-value { color: #F9FAFB; }

            .gs-week {
                background: #fff;
                border: 1px solid #E5E7EB;
                border-radius: 1rem;
                overflow: hidden;
                margin-bottom: 1.25rem;
            }
            .dark .gs-week { background: #111827; border-color: rgba(255,255,255,0.1); }
            .gs-week-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 0.75rem 1.25rem;
                background: #F9FAFB;
                border-bottom: 1px solid #E5E7EB;
                gap: 1rem;
            }
            .dark .gs-week-header { background: rgba(255,255,255,0.04); border-color: rgba(255,255,255,0.08); }
            .gs-week-title-row {
                display: flex;
                align-items: baseline;
                gap: 0.75rem;
                flex-wrap: wrap;
            }
            .gs-week-num { font-size: 0.85rem; font-weight: 700; letter-spacing: 0.05em; text-transform: uppercase; color: #111827; }
            .dark .gs-week-num { color: #F9FAFB; }
            .gs-week-date { font-size: 0.85rem; color: #6B7280; }
            .gs-week-focus { font-size: 0.85rem; color: #4B5563; font-style: italic; }
            .dark .gs-week-focus { color: #D1D5DB; }
            .gs-week-stats { display: flex; align-items: center; gap: 1rem; font-size: 0.75rem; color: #6B7280; flex-shrink: 0; }
            .gs-week-km { font-weight: 600; color: #374151; font-size: 0.85rem; }
            .dark .gs-week-km { color: #E5E7EB; }

            .gs-day {
                display: flex;
                align-items: stretch;
                width: 100%;
                background: transparent;
                border: 0;
                padding: 0;
                margin: 0;
                cursor: pointer;
                text-align: left;
                border-bottom: 1px solid #F3F4F6;
                transition: background-color 120ms ease;
            }
            .dark .gs-day { border-bottom-color: rgba(255,255,255,0.04); }
            .gs-day:hover { background: #FAFAFA; }
            .dark .gs-day:hover { background: rgba(255,255,255,0.03); }
            .gs-day:last-child { border-bottom: 0; }
            .gs-day-bar { width: 4px; flex-shrink: 0; }
            .gs-day-date {
                width: 96px;
                padding: 1rem;
                display: flex;
                flex-direction: column;
                justify-content: center;
                border-right: 1px solid #F3F4F6;
            }
            .dark .gs-day-date { border-right-color: rgba(255,255,255,0.04); }
            .gs-day-dow { font-size: 0.7rem; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; color: #6B7280; }
            .gs-day-md { font-size: 1.1rem; font-weight: 700; color: #111827; line-height: 1.2; }
            .dark .gs-day-md { color: #F9FAFB; }
            .gs-day-body { flex: 1 1 auto; padding: 1rem; min-width: 0; }
            .gs-day-row1 { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.25rem; flex-wrap: wrap; }
            .gs-day-title { font-size: 0.9rem; font-weight: 500; color: #111827; }
            .dark .gs-day-title { color: #F9FAFB; }
            .gs-day-desc { font-size: 0.85rem; color: #4B5563; line-height: 1.4; }
            .dark .gs-day-desc { color: #D1D5DB; }
            .gs-day-stats {
                padding: 1rem;
                display: flex;
                flex-direction: column;
                align-items: flex-end;
                justify-content: center;
                min-width: 100px;
                flex-shrink: 0;
            }
            .gs-day-km { font-size: 1rem; font-weight: 700; color: #111827; }
            .dark .gs-day-km { color: #F9FAFB; }
            .gs-day-pace { font-size: 0.75rem; color: #6B7280; font-weight: 500; }
            .gs-day-chev { padding: 0 0.75rem; display: flex; align-items: center; color: #D1D5DB; flex-shrink: 0; }
            .gs-day:hover .gs-day-chev { color: #6B7280; }

            .gs-badge {
                display: inline-flex;
                align-items: center;
                gap: 0.25rem;
                padding: 0.15rem 0.6rem;
                border-radius: 999px;
                font-size: 0.75rem;
                font-weight: 600;
                white-space: nowrap;
            }

            .gs-add-btn {
                display: block;
                width: 100%;
                background: transparent;
                border: 0;
                padding: 0.75rem;
                font-size: 0.85rem;
                font-weight: 500;
                color: #6B7280;
                cursor: pointer;
                border-top: 1px solid #F3F4F6;
                transition: color 120ms;
            }
            .dark .gs-add-btn { border-top-color: rgba(255,255,255,0.04); }
            .gs-add-btn:hover { color: #4F46E5; }
        </style>

        {{-- Hero summary --}}
        <div class="gs-summary">
            <div class="gs-summary-cell grow">
                <div class="gs-label">Plan</div>
                <div class="gs-value">{{ $goal->name }}</div>
            </div>
            <div class="gs-summary-cell">
                <div class="gs-label">Race day</div>
                <div class="gs-value">{{ $goal->target_date?->format('D, M j Y') ?? '—' }}</div>
            </div>
            <div class="gs-summary-cell">
                <div class="gs-label">Weeks</div>
                <div class="gs-value">{{ $goal->trainingWeeks->count() }}</div>
            </div>
            <div class="gs-summary-cell">
                <div class="gs-label">Sessions</div>
                <div class="gs-value">{{ $totalDays }}</div>
            </div>
            <div class="gs-summary-cell">
                <div class="gs-label">Total volume</div>
                <div class="gs-value">{{ number_format($totalKm, 0) }} km</div>
            </div>
        </div>

        {{-- Weeks --}}
        @forelse ($goal->trainingWeeks->sortBy('week_number') as $week)
            @php
                $weekKm = (float) ($week->total_km ?? 0);
                $weekDayCount = $week->trainingDays->count();
            @endphp

            <div class="gs-week">
                <div class="gs-week-header">
                    <div class="gs-week-title-row">
                        <div class="gs-week-num">Week {{ $week->week_number }}</div>
                        @if ($week->starts_at)
                            <div class="gs-week-date">{{ $week->starts_at->format('M j') }}</div>
                        @endif
                        @if ($week->focus)
                            <div class="gs-week-focus">· {{ $week->focus }}</div>
                        @endif
                    </div>
                    <div class="gs-week-stats">
                        <span>{{ $weekDayCount }} {{ Str::plural('session', $weekDayCount) }}</span>
                        <span class="gs-week-km">{{ number_format($weekKm, 0) }} km</span>
                    </div>
                </div>

                @foreach ($week->trainingDays->sortBy('order') as $day)
                    @php
                        $type = $day->type;
                        $emoji = $type?->emoji() ?? '·';
                        $typeLabel = $type?->label() ?? 'Unset';
                        $paceText = $day->target_pace_seconds_per_km
                            ? $this->paceToText($day->target_pace_seconds_per_km)
                            : null;

                        $palette = match ($type?->value) {
                            'easy'      => ['bar' => '#34D399', 'bg' => '#D1FAE5', 'fg' => '#065F46'],
                            'tempo'     => ['bar' => '#FBBF24', 'bg' => '#FEF3C7', 'fg' => '#92400E'],
                            'interval'  => ['bar' => '#FB7185', 'bg' => '#FFE4E6', 'fg' => '#9F1239'],
                            'long_run'  => ['bar' => '#38BDF8', 'bg' => '#E0F2FE', 'fg' => '#075985'],
                            'threshold' => ['bar' => '#A78BFA', 'bg' => '#EDE9FE', 'fg' => '#5B21B6'],
                            default     => ['bar' => '#D1D5DB', 'bg' => '#F3F4F6', 'fg' => '#374151'],
                        };
                    @endphp

                    <button type="button" class="gs-day" wire:click="openEditDay({{ $day->id }})">
                        <div class="gs-day-bar" style="background-color: {{ $palette['bar'] }};"></div>

                        <div class="gs-day-date">
                            <div class="gs-day-dow">{{ $day->date?->format('D') ?? '—' }}</div>
                            <div class="gs-day-md">{{ $day->date?->format('M j') ?? '—' }}</div>
                        </div>

                        <div class="gs-day-body">
                            <div class="gs-day-row1">
                                <span class="gs-badge" style="background-color: {{ $palette['bg'] }}; color: {{ $palette['fg'] }};">
                                    <span>{{ $emoji }}</span>
                                    <span>{{ $typeLabel }}</span>
                                </span>
                                @if ($day->title)
                                    <span class="gs-day-title">{{ $day->title }}</span>
                                @endif
                            </div>
                            @if ($day->description)
                                <div class="gs-day-desc">{{ $day->description }}</div>
                            @endif
                        </div>

                        <div class="gs-day-stats">
                            @if ($day->target_km)
                                <div class="gs-day-km">{{ rtrim(rtrim(number_format((float) $day->target_km, 1), '0'), '.') }} km</div>
                            @endif
                            @if ($paceText)
                                <div class="gs-day-pace">{{ $paceText }}/km</div>
                            @endif
                        </div>

                        <div class="gs-day-chev">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
                            </svg>
                        </div>
                    </button>
                @endforeach

                <button type="button" class="gs-add-btn" wire:click="addDay({{ $week->id }})">
                    + Add a session
                </button>
            </div>
        @empty
            <x-filament::section>
                <p>No training weeks yet.</p>
            </x-filament::section>
        @endforelse

        {{-- Filament-managed action modal renders here. The custom modal we
             used to ship rendered scrolled-mid-screen and lacked overflow
             handling; this gives us a properly scrollable Filament dialog. --}}
        <x-filament-actions::modals />
    @endif
</x-filament-panels::page>
