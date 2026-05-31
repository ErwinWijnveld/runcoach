# Shareable run card — V1 with route — implementation plan

**Date**: 2026-05-22
**Spec**: `docs/superpowers/specs/2026-05-22-shareable-run-card.md`
**Status**: ready to start

## Overview

Implementatie in 5 logische commits, gepland in deze volgorde zodat elk commit afzonderlijk testbaar + reviewable is. Volledig iOS-only (HealthKit + WorkoutKit). Backend is bijna ongewijzigd — alle "magic" zit in Flutter + Swift.

## Commit plan

### Commit 1 — Native iOS `HKWorkoutRouteQuery` bridge

**Files** (allemaal nieuw of registratie):
- `app/ios/Runner/WorkoutRoute.swift` (nieuw) — singleton + `nl.runcoach/workout-route` MethodChannel
- `app/ios/Runner/AppDelegate.swift` — register de channel (volg pattern van `PushNotifications.shared.register(with:)`)
- `app/ios/Runner/Runner.xcodeproj/project.pbxproj` — 4 registratiepunten (`PBXBuildFile`, `PBXFileReference`, `PBXGroup`, `PBXSourcesBuildPhase`) — volg `WorkoutScheduling.swift` als template
- `app/lib/features/wearable/services/workout_route_service.dart` (nieuw) — Dart-zijde MethodChannel wrapper

**Methode-shape:**
```swift
// Native
func fetchRoute(workoutUuid: String) -> [["lat": Double, "lng": Double, "t": Int]]
// of in geval van treadmill / no-GPS:
// returnt lege array {points: []}
```

**Auth-check:** ons bestaande HealthKit-permission dekt routes (zelfde scope als workouts). Geen aparte prompt.

**Implementatie:**
1. `HKSampleQuery` met `HKQuery.predicateForObject(with: UUID(uuidString: workoutUuid))` om de workout te vinden
2. Voor elke `HKWorkoutRoute` sample: `HKWorkoutRouteQuery` → itereer `[CLLocation]`
3. Flatten naar `[{lat, lng, t}]` (kort om JSON klein te houden)
4. Returneer via `result()`

**Edge:** workout niet gevonden → returnt lege array (gracieuze degradatie), niet error. Treadmill (geen `HKWorkoutRoute`) → eveneens lege array.

**Tests:** geen unit tests (iOS-only, vereist device). Smoke-test handmatig na implementatie.

---

### Commit 2 — Route ingestion in sync batch

**Files:**
- `app/lib/features/wearable/services/health_kit_service.dart` — voor elke workout in de batch ook `WorkoutRouteService.fetchRoute()` aanroepen; voeg `route` toe aan de payload onder `raw_data.route`
- `api/app/Http/Controllers/WearableActivityController.php` — verifieer dat `raw_data.route` accepted is in de bestaande validator (waarschijnlijk al via passthrough; check + voeg expliciete rule toe als `raw_data` strict gevalideerd wordt)
- `api/tests/Feature/Http/WearableActivityIngestionTest.php` — bestaande test uitbreiden of nieuwe `test_route_data_is_persisted_in_raw_data` toevoegen

**Wat NIET nodig:**
- Geen schema migration (`raw_data` JSON kolom bestaat)
- Geen aparte endpoint

**Performance:** een marathon = ~3-5k punten ≈ ~80KB JSON. De huidige batch van 200 activiteiten gaat de POST body niet richting de PHP-limiet (8MB) drijven. Voor zekerheid: chunk de native fetch in batches van 20 om memory pressure te beperken.

**Test:** unit-test op de Laravel-zijde dat een POST met `raw_data.route: [...]` correct persist.

---

### Commit 3 — Share-card widget + route polyline painter

**Files** (allemaal nieuw):
- `app/lib/features/share/painters/route_polyline_painter.dart` — `CustomPainter` met:
  - Douglas-Peucker simplification (epsilon ≈ 0.0001 lat/lon delta, max 500 punten)
  - Lat/lng → screen coords via bounding-box normalisatie (centered in 60% × 60% area)
  - Stroke met gold gradient (`Shader.linearGradient`), 8px, `StrokeCap.round`, `StrokeJoin.round`
  - `progress` parameter (0.0 → 1.0) voor de stroke-draw animatie — gebruikt `Path.computeMetrics()` + `extractPath(0, length * progress)`
  - Start-marker (gold disc 12px) + end-marker (gold ring 12px) — alleen renderen als `progress >= eindMarker_threshold`
- `app/lib/features/share/widgets/run_share_card.dart` — de full 9:16 widget:
  - Fixed aspect ratio 9:16 (1080×1920 logische pixels, of relatief sized)
  - Cream background + radial gold accent in top-right corner
  - `RunCoreLogo` eyebrow (hergebruik van `app/lib/core/widgets/runcore_logo.dart`, in zwart)
  - `RoutePolylinePainter` in 60% × 60% van de bovenste helft (alleen als route data aanwezig)
  - Italic Garamond verdict (eerste bold-zin van AI feedback, parsed met regex `/\*\*(.+?)\*\*/`)
  - 2 rijen KPI tiles (distance + time + pace bovenaan; HR + compliance % onderaan)
  - Animaties met `flutter_animate` per spec-tabel (stroke 1200ms, markers pop-in, verdict slide-up, KPIs stagger)
- `app/lib/features/share/utils/feedback_verdict_extractor.dart` — pure functie `extractVerdict(String? aiFeedback) → String?` die de eerste `**...**` matcht of fallback `split('.').first`

**Tests:**
- `test/features/share/painters/route_polyline_painter_test.dart` — Douglas-Peucker correctheid (gegeven 10000 punten, blijft ≤500), bounding box normalisatie, progress-clipping
- `test/features/share/utils/feedback_verdict_extractor_test.dart` — bold-parse, fallback to first sentence, empty / null handling
- `test/features/share/widgets/run_share_card_golden_test.dart` — golden test in EN + NL met sample run, met-route + zonder-route varianten (4 goldens totaal)

---

### Commit 4 — Sheet + share-export + iOS share sheet

**Files** (allemaal nieuw + één pubspec):
- `app/pubspec.yaml` — voeg `share_plus: ^10.0.0` (of huidige stabiele major) toe als nog niet aanwezig
- `app/lib/features/share/services/share_card_exporter.dart` — converteer `RepaintBoundary` naar PNG:
  - `GlobalKey` → `RenderRepaintBoundary` → `toImage(pixelRatio: 3.0)`
  - `ByteData` → PNG → temp file in `path_provider.getTemporaryDirectory()`
  - Returnt `File` pad voor share sheet
  - Try/catch + 2× pixelRatio fallback bij OOM op oudere devices
- `app/lib/features/share/widgets/run_celebration_sheet.dart` — full-screen `showCupertinoModalPopup`:
  - Top: handle bar + sluit-knop (linksboven, conform `WorkoutChatSheet` pattern)
  - Center: `RunShareCard` in `RepaintBoundary` + `AspectRatio(9/16)` op ~70% breedte
  - Bottom: één gold "Share" CTA + subtle "Tap to save or share with friends" label
  - On share tap: wacht tot animatie klaar is (2400ms) → `ShareCardExporter.export(key)` → `Share.shareXFiles([XFile(path)])`
- `app/lib/features/share/widgets/run_celebration_sheet.dart` — public API `RunCelebrationSheet.show(context, activity, result)`

**Tests:**
- Widget test op de sheet zelf is brittle (geheel Stack + animaties). Skip; testen handmatig op device.
- Exporter unit-test: skip (vereist Flutter binding voor `toImage`).

---

### Commit 5 — Popup trigger + inline button + i18n + backfill

**Files:**
- `app/lib/features/share/providers/celebration_provider.dart` (nieuw) — `@Riverpod(keepAlive: true)`:
  - `findCelebratableRun()` → query bestaande `wearable_activities` voor de meest recente run met `ai_feedback` non-null en `id > prefs.last_celebrated_activity_id` en `start_date >= 7d ago`
  - `markCelebrated(activityId)` → schrijft `last_celebrated_activity_id` naar `shared_preferences`
- `app/lib/app.dart` — hook in `_BootPopupHost` (na de notifications check):
  - Skip popup wanneer de huidige route niet `/dashboard` is (voorkomt dat een push-tap naar `/schedule/day/{id}` overschreven wordt door de popup)
  - Skip wanneer notifications-popup al gefired heeft (niet 2 modals op één boot)
- `app/lib/features/schedule/screens/training_day_detail_screen.dart` — voeg "Share this run" secondary CTA toe in de Coach Analysis card (alleen voor completed dagen met `ai_feedback` non-null)
- `app/lib/features/wearable/services/health_kit_service.dart` — backfill: bij eerste app-open na update (gate met een `shared_preferences` flag `route_backfill_done_v1`), batch-fetch routes voor alle wearable_activities zonder `raw_data.route`, met `start_date >= 30 days ago`. Achtergrond, niet-blocking.
- `app/lib/l10n/app_en.arb` + `app/lib/l10n/app_nl.arb` — ~10 strings:
  - `runShareSheetCta` — "Share this run" / "Deel deze run"
  - `runShareSheetSubtitle` — "Tap to save or share with friends" / "Tik om op te slaan of te delen"
  - `runShareKpiDistance` — "DISTANCE" / "AFSTAND"
  - `runShareKpiTime` — "TIME" / "TIJD"
  - `runShareKpiAvgPace` — "AVG PACE" / "GEM. TEMPO"
  - `runShareKpiAvgHr` — "AVG BPM" / "GEM. BPM"
  - `runShareKpiCompliance` — "ON-PLAN" / "OP SCHEMA"
  - `runShareIndoorPill` — "INDOOR RUN" / "BINNEN GELOPEN"
  - `runShareInlineCta` — "Share this run" / "Deel deze run" (op detail screen)
  - `runShareBarrierLabel` — "Run summary" / "Run samenvatting" (a11y label)
- Codegen: `flutter gen-l10n`

**Tests:**
- `test/features/share/providers/celebration_provider_test.dart` — findCelebratableRun: returnt niets als geen runs, returnt nieuwste als > last_celebrated_activity_id, skipt runs zonder ai_feedback, skipt runs ouder dan 7d
- Geen widget test voor de boot popup (geheel `_BootPopupHost` is dialog-spawning logica, getest via handmatige flow)

---

## Files touched summary

| Area | New | Modified |
|---|---|---|
| iOS native | 1 (`WorkoutRoute.swift`) | 2 (`AppDelegate.swift`, `project.pbxproj`) |
| Flutter — services | 3 (`workout_route_service`, `share_card_exporter`, `celebration_provider`) | 1 (`health_kit_service`) |
| Flutter — widgets | 3 (`run_share_card`, `run_celebration_sheet`, `route_polyline_painter`) | 2 (`app.dart`, `training_day_detail_screen`) |
| Flutter — utils | 1 (`feedback_verdict_extractor`) | — |
| Flutter — l10n | — | 2 ARB files |
| Tests | 4 (painter, extractor, golden, provider) | 1 (ingestion) |
| Backend | — | 1 (controller validation if needed) |
| Spec/CLAUDE.md | — | 1 (CLAUDE.md bullet under Current state) |

Totaal ~12 nieuwe files, ~10 wijzigingen.

## Pre-flight checks

Voor commit 1 starten — verifieer dat:
- `share_plus` past in de huidige Flutter SDK / Dart constraint (`pubspec.yaml`)
- `HKWorkoutRoute` toegang werkelijk valt onder bestaande HealthKit scope (test op device door éénmaal `HKWorkoutRouteQuery` te firen na huidige permission grant — als het werkt, OK; anders moet `Info.plist` of entitlements uitgebreid worden, wat een aparte App Store Review-trigger is)
- App Store Review-impact: nieuwe `HKWorkoutRoute` reads tellen onder bestaande HealthKit usage. Geen nieuwe entitlement, geen reviewer-flag verwacht.

## Test plan (manueel, op device)

Per spec sectie "Test plan", de volledige 11-stappen flow. Cruciale gates:
1. Outdoor run met GPS → route in `raw_data.route` aanwezig na sync
2. Wacht tot `GenerateActivityFeedback` job klaar is (~1-2 min via worker, of `php artisan queue:work` lokaal)
3. App opnieuw open → popup verschijnt met correcte run
4. Verifieer animatie: stroke draw zichtbaar 200-1400ms, markers pop in, verdict slide-up, KPIs staggered
5. Share → iOS share sheet → "Save image" → check Photos: PNG zonder gehavende animatie-frames
6. Dismiss → herhaal app open → popup verschijnt NIET (marker correct)
7. Inline button op training-day detail → zelfde card on-demand
8. Treadmill run → no-route fallback variant
9. NL locale → labels in NL
10. Marathon-test: 42km run met ~3000 punten → polyline rendered fluid, geen frame drops
11. Reduce Motion ON → animaties skipped, direct rest-state

## Commit plan

1. **Commit 1**: iOS native bridge + Dart wrapper service (geen UI, alleen plumbing)
2. **Commit 2**: Route ingestion in sync batch + backend validation + ingestion test
3. **Commit 3**: Painter + share card widget + verdict extractor + 3 unit/golden tests
4. **Commit 4**: Sheet + exporter + `share_plus` dependency
5. **Commit 5**: Boot popup hook + inline CTA + backfill + i18n + CLAUDE.md bullet

Geen push, geen iOS build, geen TestFlight — wachten op expliciete instructie zoals altijd.

## Open / niet-blokkerend

- **Privacy zones** (start/end thuis) — V2 feature. Lijst staat in spec onder "Deferred ideas". V1 toont de route zoals hij is.
- **Square / story duals** — V2.
- **Pro entitlement** — `ai_feedback` is al pro-gated via `GenerateActivityFeedback`'s `isPro()` check. Niet-Pro runners hebben dus geen ai_feedback en de popup zal niet firen voor hen. Inline knop checkt simpelweg `result.aiFeedback != null` — natuurlijke gating.
- **Localization van KPI-getallen** — `5:08/KM` werkt in beide talen. Geen problemen met decimal comma's verwacht voor V1 (numeriek minimaal).
