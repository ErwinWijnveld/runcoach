{{--
    App-style result panel for the edit-day modal — mirrors the Flutter
    training result screen: compliance ring + per-sub-score bars on top,
    then the Target vs Actual comparison card, the activity extras line,
    and the AI feedback the runner received.

    Expects: $panel (see GoalSchedule::resultPanelData).
    Shared styles (.rc-ring, .rc-band-*, .rc-result-*) live in the
    goal-schedule page <style> block.
--}}
<div class="rc-result-panel">
    <div class="rc-result-top">
        @include('filament.coach.components.compliance-ring', ['score' => $panel['score'], 'size' => 96, 'stroke' => 6])

        @if ($panel['bars'] !== [])
            <div class="rc-result-bars">
                @foreach ($panel['bars'] as $bar)
                    @php $pct = max(4, min(100, (int) round(((float) $bar['grade']) * 10))); @endphp
                    <div class="rc-bar">
                        <div class="rc-bar-track">
                            <div class="rc-bar-fill rc-bg-{{ $bar['band'] }}" style="height: {{ $pct }}%;"></div>
                        </div>
                        <div class="rc-bar-grade rc-band-{{ $bar['band'] }}">{{ $bar['grade'] }}</div>
                        <div class="rc-bar-label">{{ $bar['label'] }}</div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>

    @if ($panel['rows'] !== [])
        <div class="rc-comp-card">
            <table class="rc-comp-table">
                <thead>
                    <tr>
                        <th></th>
                        <th>Target</th>
                        <th>Actual</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($panel['rows'] as $row)
                        <tr>
                            <td class="rc-comp-label">{{ $row['label'] }}</td>
                            <td class="rc-comp-target">{{ $row['target'] }}</td>
                            <td class="rc-comp-actual {{ $row['band'] !== null ? 'rc-band-'.$row['band'] : '' }}">{{ $row['actual'] }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @endif

    @if ($panel['activity'] !== null)
        <div class="rc-result-activity">{{ $panel['activity'] }}</div>
    @endif

    @if ($panel['feedback'] !== null)
        <div class="rc-result-feedback">{!! $panel['feedback'] !!}</div>
    @endif
</div>
