{{--
    Circular compliance ring — HTML/SVG port of the Flutter `ComplianceRing`
    (app/lib/core/widgets/compliance_ring.dart): a 15%-alpha track, a round-cap
    progress arc starting at 12 o'clock, and the 0-10 grade centered in the
    band color. Band thresholds mirror `ComplianceColors` (good ≥ 8.0,
    ok ≥ 5.0).

    Expects: $score (float, 0-10), $size (px). Optional: $stroke, $fontSize.
--}}
@php
    $score01 = max(0.0, min(1.0, ((float) $score) / 10));
    $ringColor = $score01 >= 0.8 ? '#34C759' : ($score01 >= 0.5 ? '#E9B638' : '#8F3A3A');
    $stroke = $stroke ?? max(5, (int) round($size * 0.056));
    $half = $size / 2;
    $radius = ($size - $stroke) / 2;
    $circumference = 2 * M_PI * $radius;
    $fontSize = $fontSize ?? (int) round($size * 0.3);
@endphp
<div class="rc-ring" style="width: {{ $size }}px; height: {{ $size }}px;">
    <svg width="{{ $size }}" height="{{ $size }}" viewBox="0 0 {{ $size }} {{ $size }}" fill="none" aria-hidden="true">
        <circle cx="{{ $half }}" cy="{{ $half }}" r="{{ $radius }}"
            stroke="{{ $ringColor }}" stroke-opacity="0.15" stroke-width="{{ $stroke }}" />
        <circle cx="{{ $half }}" cy="{{ $half }}" r="{{ $radius }}"
            stroke="{{ $ringColor }}" stroke-width="{{ $stroke }}" stroke-linecap="round"
            stroke-dasharray="{{ number_format($score01 * $circumference, 2, '.', '') }} {{ number_format($circumference, 2, '.', '') }}"
            transform="rotate(-90 {{ $half }} {{ $half }})" />
    </svg>
    <span class="rc-ring-grade" style="color: {{ $ringColor }}; font-size: {{ $fontSize }}px;">{{ number_format((float) $score, 1) }}</span>
</div>
