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
            /* RunCoach schedule — mirrors the Flutter schedule overview.
               Tokens are defined in resources/css/filament/coach/theme.css
               (--rc-cream, --rc-card, --rc-gold, --rc-ink, ...). */

            .gs-summary {
                display: grid;
                grid-template-columns: 1.6fr repeat(4, 1fr);
                gap: 1.25rem;
                align-items: center;
                padding: 1.25rem 1.5rem;
                background: var(--rc-card);
                border: 1px solid var(--rc-border-soft);
                border-radius: 1.5rem;
                margin-bottom: 1.5rem;
                box-shadow: 0 2px 12px rgba(55, 40, 15, 0.04);
            }
            @media (max-width: 900px) {
                .gs-summary { grid-template-columns: repeat(2, 1fr); }
            }
            .gs-label {
                font-family: var(--rc-font-display);
                font-size: 0.65rem;
                font-weight: 600;
                letter-spacing: 0.12em;
                text-transform: uppercase;
                color: var(--rc-eyebrow);
            }
            .gs-value {
                font-family: var(--rc-font-serif);
                font-style: italic;
                font-size: 1.4rem;
                font-weight: 500;
                color: var(--rc-ink);
                margin-top: 4px;
                line-height: 1.15;
            }
            .gs-value-num {
                font-family: var(--rc-font-body);
                font-style: normal;
                font-size: 1.25rem;
                font-weight: 600;
                color: var(--rc-ink);
                margin-top: 4px;
            }

            .gs-week {
                background: var(--rc-card);
                border: 1px solid var(--rc-border-soft);
                border-radius: 1.5rem;
                overflow: hidden;
                margin-bottom: 1rem;
                box-shadow: 0 2px 12px rgba(55, 40, 15, 0.04);
            }
            .gs-week-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 1rem 1.25rem;
                background: var(--rc-card-soft);
                border-bottom: 1px solid var(--rc-border-soft);
                gap: 1rem;
            }
            .gs-week-title-row {
                display: flex;
                align-items: baseline;
                gap: 0.75rem;
                flex-wrap: wrap;
            }
            .gs-week-num {
                font-family: var(--rc-font-display);
                font-size: 0.75rem;
                font-weight: 700;
                letter-spacing: 0.14em;
                text-transform: uppercase;
                color: var(--rc-eyebrow);
            }
            .gs-week-date {
                font-family: var(--rc-font-serif);
                font-style: italic;
                font-size: 1.05rem;
                font-weight: 500;
                color: var(--rc-ink);
            }
            .gs-week-focus {
                font-family: var(--rc-font-body);
                font-size: 0.85rem;
                color: var(--rc-ink-muted);
            }
            .gs-week-stats {
                display: flex;
                align-items: center;
                gap: 1rem;
                font-family: var(--rc-font-body);
                font-size: 0.78rem;
                color: var(--rc-ink-muted);
                flex-shrink: 0;
            }
            .gs-week-km {
                font-weight: 600;
                color: var(--rc-ink);
                font-size: 0.9rem;
            }

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
                border-bottom: 1px solid var(--rc-border-soft);
                transition: background-color 120ms ease;
            }
            .gs-day:hover { background: var(--rc-card-soft); }
            .gs-day:last-of-type { border-bottom: 0; }

            .gs-day-date {
                width: 88px;
                padding: 1rem 0 1rem 1.25rem;
                display: flex;
                flex-direction: column;
                justify-content: center;
                gap: 2px;
            }
            .gs-day-dow {
                font-family: var(--rc-font-display);
                font-size: 0.65rem;
                font-weight: 700;
                letter-spacing: 0.12em;
                text-transform: uppercase;
                color: var(--rc-ink-muted);
            }
            .gs-day-md {
                font-family: var(--rc-font-serif);
                font-style: italic;
                font-size: 1.25rem;
                font-weight: 500;
                color: var(--rc-ink);
                line-height: 1.1;
            }

            .gs-day-body { flex: 1 1 auto; padding: 1rem; min-width: 0; }
            .gs-day-row1 {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                margin-bottom: 0.35rem;
                flex-wrap: wrap;
            }
            .gs-day-title {
                font-family: var(--rc-font-body);
                font-size: 0.95rem;
                font-weight: 600;
                color: var(--rc-ink);
            }
            .gs-day-desc {
                font-family: var(--rc-font-body);
                font-size: 0.85rem;
                color: var(--rc-ink-muted);
                line-height: 1.45;
            }

            .gs-day-stats {
                padding: 1rem 1.25rem;
                display: flex;
                flex-direction: column;
                align-items: flex-end;
                justify-content: center;
                min-width: 110px;
                flex-shrink: 0;
                gap: 2px;
            }
            .gs-day-km {
                font-family: var(--rc-font-body);
                font-size: 1.05rem;
                font-weight: 700;
                color: var(--rc-ink);
            }
            .gs-day-pace {
                font-family: var(--rc-font-body);
                font-size: 0.78rem;
                color: var(--rc-ink-muted);
                font-weight: 500;
            }
            .gs-day-chev {
                padding-right: 1rem;
                display: flex;
                align-items: center;
                color: var(--rc-border);
                flex-shrink: 0;
            }
            .gs-day:hover .gs-day-chev { color: var(--rc-ink-muted); }

            /* Status pill — drives the per-row state colour. */
            .gs-status-pill {
                display: inline-flex;
                align-items: center;
                gap: 0.3rem;
                padding: 0.18rem 0.55rem;
                border-radius: 999px;
                font-family: var(--rc-font-display);
                font-size: 0.62rem;
                font-weight: 700;
                letter-spacing: 0.1em;
                text-transform: uppercase;
                white-space: nowrap;
            }
            .gs-status-completed { background: var(--rc-success-bg); color: #1F7A33; }
            .gs-status-missed    { background: var(--rc-danger-bg);  color: var(--rc-danger); }
            .gs-status-today     { background: var(--rc-warn-bg);    color: #8A6618; }
            .gs-status-upcoming  { background: var(--rc-tan);        color: var(--rc-ink-muted); }

            .gs-status-dot {
                width: 0.4rem;
                height: 0.4rem;
                border-radius: 999px;
                background: currentColor;
            }

            .gs-add-btn {
                display: block;
                width: 100%;
                background: transparent;
                border: 0;
                padding: 0.9rem;
                font-family: var(--rc-font-display);
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.14em;
                text-transform: uppercase;
                color: var(--rc-ink-muted);
                cursor: pointer;
                border-top: 1px solid var(--rc-border-soft);
                transition: color 120ms, background 120ms;
            }
            .gs-add-btn:hover {
                color: var(--rc-brown-dark);
                background: var(--rc-gold-glow);
            }
        </style>

        {{-- Hero summary --}}
        <div class="gs-summary">
            <div>
                <div class="gs-label">Plan</div>
                <div class="gs-value">{{ $goal->name }}</div>
            </div>
            <div>
                <div class="gs-label">Race day</div>
                <div class="gs-value-num">{{ $goal->target_date?->format('D · M j') ?? '—' }}</div>
            </div>
            <div>
                <div class="gs-label">Weeks</div>
                <div class="gs-value-num">{{ $goal->trainingWeeks->count() }}</div>
            </div>
            <div>
                <div class="gs-label">Sessions</div>
                <div class="gs-value-num">{{ $totalDays }}</div>
            </div>
            <div>
                <div class="gs-label">Total volume</div>
                <div class="gs-value-num">{{ number_format($totalKm, 0) }} km</div>
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
                        $paceText = $day->target_pace_seconds_per_km
                            ? $this->paceToText($day->target_pace_seconds_per_km)
                            : null;

                        $status = $this->dayStatus($day);
                        $statusLabel = match ($status) {
                            'completed' => 'Completed',
                            'missed'    => 'Missed',
                            'today'     => 'Today',
                            default     => 'Upcoming',
                        };
                    @endphp

                    <button type="button" class="gs-day" wire:click="openEditDay({{ $day->id }})">
                        <div class="gs-day-date">
                            <div class="gs-day-dow">{{ $day->date?->format('D') ?? '—' }}</div>
                            <div class="gs-day-md">{{ $day->date?->format('M j') ?? '—' }}</div>
                        </div>

                        <div class="gs-day-body">
                            <div class="gs-day-row1">
                                <span class="gs-status-pill gs-status-{{ $status }}">
                                    <span class="gs-status-dot"></span>
                                    <span>{{ $statusLabel }}</span>
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
