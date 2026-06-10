<x-filament-panels::page>
    @php $goal = $this->goal; @endphp
    @if ($goal === null)
        <x-filament::section>
            <p>Goal not found.</p>
        </x-filament::section>
    @else
        @php
            $totalKm = $goal->trainingWeeks->sum('total_km');
            $planStats = $this->planResultStats($goal);
            $offPlanRuns = $this->offPlanRunsByWeek($goal);
        @endphp

        <style>
            /* RunCoach schedule — mirrors the Flutter schedule overview.
               Tokens are defined in resources/css/filament/coach/theme.css
               (--rc-cream, --rc-card, --rc-gold, --rc-ink, ...). */

            .gs-summary {
                display: grid;
                grid-template-columns: 1.6fr repeat(5, 1fr);
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

            .gs-day-ring {
                display: flex;
                align-items: center;
                padding-left: 0.25rem;
                flex-shrink: 0;
            }

            .gs-day-actual {
                font-family: var(--rc-font-body);
                font-size: 0.8rem;
                font-weight: 500;
                color: var(--rc-ink-muted);
                margin-top: 0.3rem;
            }

            .gs-week-comp {
                font-weight: 600;
                color: var(--rc-ink);
            }

            /* ---- Compliance ring (shared: hero + result modal) ----------
               Band colors are the app's ComplianceColors values. */
            .rc-band-good { color: #34C759; }
            .rc-band-ok   { color: #E9B638; }
            .rc-band-bad  { color: #8F3A3A; }
            .rc-bg-good   { background: #34C759; }
            .rc-bg-ok     { background: #E9B638; }
            .rc-bg-bad    { background: #8F3A3A; }

            .rc-ring { position: relative; display: inline-block; flex-shrink: 0; }
            .rc-ring svg { display: block; }
            .rc-ring-grade {
                position: absolute;
                inset: 0;
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: var(--rc-font-serif);
                font-weight: 500;
            }

            /* ---- Result panel in the edit-day modal --------------------- */
            .rc-result-panel { display: flex; flex-direction: column; gap: 1rem; }
            .rc-result-top { display: flex; align-items: center; gap: 1.75rem; }
            .rc-result-bars { display: flex; gap: 1.5rem; align-items: flex-end; }
            .rc-bar { display: flex; flex-direction: column; align-items: center; gap: 4px; }
            .rc-bar-track {
                width: 7px;
                height: 48px;
                border-radius: 999px;
                background: var(--rc-border-soft);
                display: flex;
                flex-direction: column;
                justify-content: flex-end;
                overflow: hidden;
            }
            .rc-bar-fill { width: 100%; border-radius: 999px; }
            .rc-bar-grade {
                font-family: var(--rc-font-serif);
                font-size: 0.9rem;
                font-weight: 600;
            }
            .rc-bar-label {
                font-family: var(--rc-font-display);
                font-size: 0.58rem;
                font-weight: 700;
                letter-spacing: 0.1em;
                text-transform: uppercase;
                color: var(--rc-ink-muted);
            }

            .rc-comp-card {
                background: var(--rc-card-soft);
                border: 1px solid var(--rc-border-soft);
                border-radius: 1rem;
                padding: 0.5rem 1.1rem;
            }
            .rc-comp-table { width: 100%; border-collapse: collapse; }
            .rc-comp-table th {
                font-family: var(--rc-font-display);
                font-size: 0.62rem;
                font-weight: 600;
                letter-spacing: 0.14em;
                text-transform: uppercase;
                color: var(--rc-ink-muted);
                text-align: right;
                padding: 0.6rem 0 0.35rem;
            }
            .rc-comp-table td { padding: 0.6rem 0; border-top: 1px solid var(--rc-border-soft); }
            .rc-comp-table tbody tr:first-child td { border-top: 0; }
            .rc-comp-label {
                font-family: var(--rc-font-body);
                font-size: 0.9rem;
                color: var(--rc-ink);
            }
            .rc-comp-target {
                font-family: var(--rc-font-serif);
                font-style: italic;
                font-size: 1.05rem;
                color: var(--rc-ink-muted);
                text-align: right;
            }
            .rc-comp-actual {
                font-family: var(--rc-font-serif);
                font-style: italic;
                font-size: 1.15rem;
                font-weight: 500;
                color: var(--rc-ink);
                text-align: right;
                padding-left: 1rem;
            }

            .rc-result-activity {
                font-family: var(--rc-font-body);
                font-size: 0.82rem;
                color: var(--rc-ink-muted);
            }
            .rc-result-feedback {
                font-family: var(--rc-font-body);
                font-size: 0.88rem;
                color: var(--rc-ink);
                line-height: 1.55;
                border-top: 1px solid var(--rc-border-soft);
                padding-top: 0.85rem;
            }
            .rc-result-feedback p { margin: 0 0 0.6rem; }
            .rc-result-feedback p:last-child { margin-bottom: 0; }

            /* ---- "Buiten schema" run tiles -------------------------------
               Mirrors Flutter's _UnplannedRunTile: calm blue accent
               (#3E72C7 with #D8E6FB glow), gradient from the right,
               km · pace subtitle in blue. */
            .gs-offplan {
                cursor: default;
                background: linear-gradient(to left, rgba(62, 114, 199, 0.12), rgba(62, 114, 199, 0) 65%);
            }
            .gs-offplan:hover { background: linear-gradient(to left, rgba(62, 114, 199, 0.12), rgba(62, 114, 199, 0) 65%); }
            .gs-offplan-pill { background: #D8E6FB; color: #3E72C7; }
            .gs-offplan-line {
                font-family: var(--rc-font-display);
                font-size: 0.72rem;
                font-weight: 700;
                color: #3E72C7;
                margin-top: 0.3rem;
            }
            .gs-offplan-plus {
                align-self: center;
                margin-right: 1.25rem;
                width: 28px;
                height: 28px;
                border-radius: 999px;
                background: #3E72C7;
                color: #fff;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 1rem;
                font-weight: 600;
                line-height: 1;
                flex-shrink: 0;
            }

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
                <div class="gs-value-num">{{ $planStats['done'] }} / {{ $planStats['total'] }} done</div>
            </div>
            <div>
                <div class="gs-label">Compliance</div>
                @if ($planStats['avg'] !== null)
                    <div style="margin-top: 6px;">
                        @include('filament.coach.components.compliance-ring', ['score' => $planStats['avg'], 'size' => 84, 'stroke' => 6])
                    </div>
                @else
                    <div class="gs-value-num">—</div>
                @endif
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
                $weekStats = $this->weekResultStats($week);
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
                        @if ($weekStats)
                            <span class="gs-week-comp">{{ $weekStats['done'] }}/{{ $weekStats['total'] }} done · avg {{ $this->formatScore($weekStats['avg']) }}</span>
                        @endif
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

                        $result = $status === 'completed' ? $day->result : null;
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
                            @if ($result)
                                <div class="gs-day-actual">{{ $this->resultSummaryLine($result) }}</div>
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

                        @if ($result)
                            <div class="gs-day-ring">
                                @include('filament.coach.components.compliance-ring', ['score' => (float) $result->compliance_score, 'size' => 44, 'stroke' => 4, 'fontSize' => 13])
                            </div>
                        @endif

                        <div class="gs-day-chev">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                                <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
                            </svg>
                        </div>
                    </button>
                @endforeach

                @foreach ($offPlanRuns[$week->id] ?? [] as $run)
                    <div class="gs-day gs-offplan">
                        <div class="gs-day-date">
                            <div class="gs-day-dow">{{ $run->start_date?->format('D') ?? '—' }}</div>
                            <div class="gs-day-md">{{ $run->start_date?->format('M j') ?? '—' }}</div>
                        </div>

                        <div class="gs-day-body">
                            <div class="gs-day-row1">
                                <span class="gs-status-pill gs-offplan-pill">
                                    <span class="gs-status-dot"></span>
                                    <span>Off-plan</span>
                                </span>
                                <span class="gs-day-title">Run outside schedule</span>
                            </div>
                            <div class="gs-offplan-line">{{ $this->offPlanRunLine($run) }}</div>
                        </div>

                        <div class="gs-offplan-plus">+</div>
                    </div>
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
