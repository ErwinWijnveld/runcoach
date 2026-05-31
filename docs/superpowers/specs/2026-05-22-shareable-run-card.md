# Shareable run card — V1 with route

**Date**: 2026-05-22
**Author**: discussie met user
**Status**: draft

## Goal

Na elke geanalyseerde run krijgt de runner één keer een pop-up te zien met een mooie, deelbare afbeelding (9:16 Instagram-story formaat) die de route, KPI's, RunCoach-branding en een AI-zinnetje toont. Doel: organische groei via shares + een unieke "RunCoach-moment" die runners niet ergens anders krijgen.

## Scope

### In scope
- Native iOS bridge (`HKWorkoutRouteQuery`) om GPS-polyline uit HealthKit te lezen
- Polyline opslag op `wearable_activities.raw_data.route`
- Flutter share-card widget (9:16, 1080×1920px export)
- Pop-up flow bij eerstvolgende app-open na nieuwe geanalyseerde run
- Inline share-knop op het training-day detail scherm (Coach Analysis card)
- iOS share sheet via `share_plus`
- Fallback variant zonder route (treadmill / no-GPS)

### Out of scope (V2)
- Square (1:1) of feed-post formaat
- Privacy zones (start/end thuis maskeren)
- Andere "memorabilia" cards (weekly summary, PR's, race-day card)
- Android (geen HealthKit; HealthConnect heeft ander route-model)
- Direct deep-link naar specifieke socials (Strava share, etc.) — share sheet is genoeg
- A/B test van card-varianten — eerst zien wat de share-rate is

## UX

### Trigger 1: pop-up bij app-open
- Op cold-start (en op `appLifecycleState=resumed` na een nieuwe geanalyseerde run), controleer of er een `wearable_activity` is met:
  - `type` ∈ `RUN_TYPES`
  - Een `TrainingResult` met `ai_feedback` non-null (= analyse compleet)
  - `id` > waarde van `shared_preferences['last_celebrated_activity_id']` (default 0)
  - `start_date` ≥ 7 dagen geleden (geen oude runs opduiken bij eerste install)
- Zo ja → toon `RunCelebrationSheet` als full-screen Cupertino modal
- Bij dismiss of share → `last_celebrated_activity_id = activity.id`. Niet bij hard-close.
- Reuse pattern: `_BootPopupHost` in `app.dart` (zelfde hook als de notifications inbox popup)

### Trigger 2: inline share button
- Op `training_day_detail_screen.dart`'s Coach Analysis card — alleen voor completed dagen met een result + analyzed AI-feedback
- Kleine secondary CTA "Share this run" naast de bestaande "Open ›" link
- Opent dezelfde `RunCelebrationSheet`, maar dan zonder de "first time" pop-up cadans

### De sheet zelf
- Full-screen `showCupertinoModalPopup` of een dedicated route
- Bovenin: handle bar + sluit-knop (X linksboven)
- Center: de share-card preview op ~70% van scherm-breedte met de juiste 9:16 verhouding
- Onder de card: één primaire knop **"Share"** (gold CTA, conform `app/CLAUDE.md` §7) → opens iOS share sheet met PNG
- Subtle subtitle eronder: "Tap to save or share with friends"
- Geen "Save to camera roll" als aparte knop — de share sheet heeft "Save image" als optie

## Card design

```
┌────────────────────────────────────┐
│ ↑ 9:16 portrait                    │
│                                    │
│ ╭──── RUNCOACH ──── 18 May 2026 ──╮│ ← eyebrow row: wordmark + date
│ │                                  ││
│ │                                  ││
│ │      ╱╲                          ││
│ │     ╱  ╲    ┌─ route polyline    ││
│ │    ╱    ╲   │   gold gradient    ││
│ │   ╱      ╲__┤   stroke 8px       ││
│ │  ╱  ╱ ╲    ╲   centered, max     ││
│ │ ╲__╱   ╲___╱   60% of card width ││
│ │                                  ││
│ ╰──────────────────────────────────╯│
│                                    │
│  "Strong negative split."          │ ← italic Garamond, AI verdict
│                                    │
│  ┌────────┬────────┬────────┐      │
│  │ 10.2KM │ 52:18  │ 5:08/KM│      │ ← KPI row 1
│  └────────┴────────┴────────┘      │
│  ┌────────────────┬─────────┐      │
│  │ 162 AVG BPM    │ 94%     │      │ ← KPI row 2 (HR + compliance)
│  │                │ ON-PLAN │      │
│  └────────────────┴─────────┘      │
│                                    │
└────────────────────────────────────┘
```

### Visual specs
- **Background**: cream (`AppColors.cream` #FAF8F4) met subtle radial gold-gradient accent in top-right corner
- **Eyebrow row**: small caps Space Grotesk 11pt, gold accent (`#785600`), letterSpacing 0.8
- **Wordmark**: "RUNCOACH" Space Grotesk 700, OR een geleverd SVG logo
- **Route polyline**:
  - Gerendered via `CustomPainter` op `Canvas` (geen Mapbox / Apple Maps tiles)
  - Normaliseer GPS-punten naar 60% × 60% bounding box, gecentreerd in upper half
  - Stroke: gold gradient → orange (`#E9B638` → `#D4831F`), 8px lineWidth, rounded caps + joins
  - Start-marker: kleine gold disc (12px)
  - End-marker: kleine gold disc met ringbody
  - Polyline simplification: Douglas-Peucker met epsilon ≈ 0.0001 lat/lon delta — beperkt to ~500 punten voor render performance
- **AI verdict**: 1 zin uit `TrainingResult.ai_feedback`, eerste zin gepakt via `split('.').first`. Garamond italic 22pt, primaryInk, max 2 regels (truncate met "…")
- **KPI tiles**:
  - White cards, `BorderRadius.circular(16)`, padding 14
  - Value: Space Grotesk 28pt 700, primaryInk
  - Label: Space Grotesk 10pt 700, inkMuted, letterSpacing 0.8, uppercase
  - HR tile groen-getint als HR-score ≥ 8, default neutraal anders
  - Compliance tile gold-getint als score ≥ 80%, danger-tint als < 50%

### KPI value formatting
- **Distance**: `result.actual_km` → "10.2KM" (1 decimaal als < 100, 0 anders)
- **Time**: `wearable_activity.duration_seconds` → "52:18" of "1:23:45"
- **Avg pace**: `result.actual_pace_seconds_per_km` → "5:08/KM"
- **Avg HR**: `result.actual_avg_heart_rate` → "162 AVG BPM"
- **Compliance**: `result.compliance_score` (0-10) → "94%" + label "ON-PLAN"

Edge: missende velden tonen "—" in plaats van "0". Compliance-tile is hidden als score null.

### Fallback (no GPS route)
- Vervang de polyline-zone door een groter KPI-blok dat de full width pakt
- Boven KPI's: kleine pill "INDOOR RUN" of "NO ROUTE DATA"
- AI verdict + KPIs blijven identiek
- Geen lege ruimte / no-route placeholder graphic — alleen typografie

## Route ingestion

### iOS native bridge
- Nieuwe Swift file `ios/Runner/WorkoutRoute.swift` (parallel aan `WorkoutScheduling.swift`, `PushNotifications.swift`)
- MethodChannel `nl.runcoach/workout-route`
- Method: `fetchRoute(workoutUuid: String) → { points: [{lat, lng, timestamp_ms}] }`
- Native flow:
  1. Find `HKWorkout` matching `UUID(uuidString: workoutUuid)` via `HKSampleQuery` predicated on UUID
  2. `HKWorkoutRouteQuery.init(workout:, sampleHandler:, ...)` to iterate route segments
  3. Per segment: `HKWorkoutRouteQuery` op de route sample → `HKQuery.predicateForSamples` levert `[CLLocation]`
  4. Returneer flat array van `{lat, lng, timestamp_ms}` aan Flutter
- Auth: HealthKit-permission die we al hebben dekt routes (zelfde scope als workouts)

### When to fetch
- Twee strategieën, kies één:
  - **(A) Eager**: tijdens de bestaande Apple Health sync (`HealthKitService.fetchWorkouts`), voor elke nieuwe workout ook de route ophalen en in dezelfde batch naar `POST /wearable/activities` sturen
  - **(B) Lazy**: alleen ophalen wanneer de runner de pop-up zou zien (server signaleert "route ontbreekt nog" + Flutter fetcht en post-update't)
- **Aanbevolen: (A) eager**, zelfde batch — minder native round-trips, route is meteen overal beschikbaar (bv. ook voor de inline share-knop op older runs)
- Marathon = ~3-5k route punten → ~50-100KB JSON per run, prima

### Backend
- Schema: bestaande `wearable_activities.raw_data` JSON kolom — voeg `route` key toe: `{ "route": [{lat, lng, t}, ...] }` (afkortingen om JSON size te beperken)
- Geen schema migration nodig
- `WearableActivityController::store` accepteert deze al via `raw_data` passthrough — verificatie: check de huidige `store` validator
- Geen aparte endpoint, route flows mee met de normale activity-upsert

### Backfill voor bestaande activiteiten
- Op app-open: voor alle `wearable_activities` met `type ∈ RUN_TYPES`, `raw_data.route` null, `start_date >= 30 days ago`, en `id <= last_celebrated_activity_id` → batch fetch routes, PATCH naar backend
- Achtergrond, niet-blocking. Werkt eenmalig bij rollout zodat oudere runs ook deelbaar zijn.

## Files to touch (high-level)

### Backend (`api/`)
- (Mogelijk) `WearableActivityController::store` — verifieer dat `raw_data.route` accepted is, geen rules-strictheid die het dropt
- (Optioneel) `WearableActivityController::patchRoute` endpoint als de backfill flow apart wil zijn (maar simpeler: PUT/upsert de hele activity opnieuw)

### Flutter (`app/`)
- **iOS native**:
  - `ios/Runner/WorkoutRoute.swift` (nieuw)
  - `ios/Runner/AppDelegate.swift` — register de methodchannel (volg het patroon van `PushNotifications`)
  - `ios/Runner/Runner.xcodeproj/project.pbxproj` — vier registratiepunten zoals `WorkoutScheduling.swift`
- **Flutter side**:
  - `lib/features/wearable/services/workout_route_service.dart` (nieuw) — methodchannel wrapper
  - `lib/features/wearable/services/health_kit_service.dart` — call `WorkoutRouteService.fetchRoute()` per workout in de batch
  - `lib/features/share/widgets/run_celebration_sheet.dart` (nieuw) — full-screen modal
  - `lib/features/share/widgets/run_share_card.dart` (nieuw) — de 9:16 RepaintBoundary widget
  - `lib/features/share/painters/route_polyline_painter.dart` (nieuw) — CustomPainter voor de gestylized polyline
  - `lib/features/share/services/share_card_exporter.dart` (nieuw) — `RepaintBoundary.toImage()` → PNG bytes → temp file → `share_plus`
  - `lib/features/share/providers/celebration_provider.dart` (nieuw) — checkt of er een nieuwe celebratable run is, tracks `last_celebrated_activity_id`
  - `lib/app.dart` — hook in `_BootPopupHost` na de notifications check
  - `lib/features/schedule/screens/training_day_detail_screen.dart` — inline "Share this run" CTA in/onder Coach Analysis card
  - `lib/l10n/app_en.arb` + `app_nl.arb` — ~10 nieuwe strings (titel, CTA, no-route fallback label, "on-plan", etc.)
- **Dependencies**:
  - `share_plus` — voeg toe aan `pubspec.yaml` indien nog niet aanwezig
  - Geen mapbox / google_maps_flutter — pure CustomPainter
- **Tests**:
  - `test/features/share/painters/route_polyline_painter_test.dart` — normalisatie + Douglas-Peucker
  - `test/features/share/widgets/run_share_card_golden_test.dart` — golden test in EN + NL met sample data
  - Native bridge wordt niet unit-getest (iOS-only, vereist device)

## Edge cases

1. **Treadmill / GymKit / indoor**: `HKWorkoutRoute` is null → service returnt `{points: []}` → Flutter card valt terug op no-route variant
2. **Heel korte run** (<500m, <5 minuten): popup wel firen — die runner verdient toch z'n moment. Compliance tile kan rare waardes geven maar dat is een aparte fix.
3. **Run zonder gematchte TrainingResult**: geen AI-feedback dus ook geen popup. Wel deelbaar via een tweede inline-knop op het wearable-activity detail scherm later (out of scope V1).
4. **Multi-segment routes** (pauses mid-run): segmenten flatten en aan elkaar plakken; de gaps zijn klein genoeg dat de polyline er natuurlijk uitziet. Bij segment-pauze met grote sprong: laat de Douglas-Peucker simplificatie de noise wegnemen.
5. **Privacy** (start/end thuis): niet in V1. Adresseren als feature-flag of "trim first/last 200m" toggle in V2.
6. **HR data ontbreekt**: HR-tile hidden, compliance-tile pakt de volle width naast distance/time/pace.
7. **AI feedback ontbreekt of is leeg**: skip de italic-verdict regel, vergroot de KPI-block iets om de ruimte te vullen.
8. **Card export crash op oudere devices** (toImage geheugen): pixel ratio toggle — render op 2.0× ipv 3.0× als device geheugen krap is. Wrap in try/catch met fallback "Couldn't generate card, tap to retry".
9. **User dismisst popup**: marker zetten, niet opnieuw firen voor dezelfde run. Maar elders nog wel deelbaar via training-day detail.
10. **Push notification → tap → app open**: als de notification de gebruiker naar `/schedule/day/{id}` brengt, de popup niet ook nog firen (zou bovenop de gepushte route landen). Skip popup als de huidige route niet `/dashboard` is.

## Resolved decisions

1. ✅ **Route fetch: eager** — meeliftend op de bestaande HealthKit sync batch
2. ✅ **Backfill: laatste 30 dagen** bij eerste app-open na update (eenmalig batched), zodat bestaande runs ook deelbaar zijn
3. ✅ **Wordmark: hergebruik `RunCoreLogo`** (`app/lib/core/widgets/runcore_logo.dart`) — bestaand widget met star SVG + "RunCore" wordmark. Renderen op cream achtergrond in zwart. Brand is RunCore in-app (RunCoach = projectnaam)
4. ✅ **Polyline: gold gradient** (`#E9B638 → #D4831F`), 8px stroke, rounded caps. Matcht de app-styling
5. ✅ **Verdict: eerste vetgedrukte zin** — `ActivityFeedbackAgent` opent altijd met `**...**`. Parse de inhoud tussen de eerste `**` en `**` als verdict-zin. Fallback op `split('.').first` als geen bold gevonden
6. ✅ **Square variant: skip in V1**

## Animatie

De card moet "mooi intro-animaten" wanneer de sheet opent. Vier gestapelde animaties met `flutter_animate` (al in de dependencies — gebruikt door `intro_fx.dart`):

| Element | Animatie | Timing |
|---|---|---|
| Background gradient + RunCore eyebrow | Fade-in van 0 → 1 | 0ms → 300ms (`easeOut`) |
| Route polyline | **Stroke draw** van start naar finish via `CustomPainter` `progress` param 0 → 1, gold gradient sweept met de stroke mee | 200ms → 1400ms (`easeOutCubic`) |
| Start/end markers | Pop-in (scale 0 → 1.1 → 1) na de stroke arriveert | 1300ms (start) / 1450ms (end), 250ms duration, `easeOutBack` |
| AI verdict-zin | Fade + 8px slide-up | 1500ms → 1900ms (`easeOutCubic`) |
| KPI tiles | Staggered fade + 8px slide-up, 80ms tussen tiles | 1700ms → 2300ms |

Totale duur: ~2.3s tot rust. `MediaQuery.disableAnimations` (Reduce Motion) skipt alles — render direct in rest-state. Pattern: zelfde respect als `IntroFx`.

Bij **export naar PNG** wordt eerst gewacht tot de animatie compleet is (`await Future.delayed(2400ms)` of een completion-callback), zodat `RepaintBoundary.toImage()` de gehele card vastlegt. Geen halve frames.

## Fallback (no GPS route) — uitwerking

- De polyline-zone wordt vervangen door een groter KPI-blok dat de full width pakt
- Boven de KPI's: kleine pill `INDOOR RUN` (gold-glow eyebrow, conform `app/CLAUDE.md` §7)
- Card hoogte blijft 9:16 — de extra ruimte wordt opgevuld door grotere KPI-typografie + meer breathing room
- Animatie versie: skipt stroke-draw + markers; verdict + KPIs animaten zoals normaal
- Net zo deelbaar als de standaard variant

## Test plan (manueel)

1. Voltooi een outdoor run met GPS → laat hem syncen → verifieer dat de route in `wearable_activities.raw_data.route` staat
2. Wacht tot `GenerateActivityFeedback` klaar is (1-2 min via worker)
3. Open app opnieuw → popup verschijnt met de juiste run
4. Verifieer card: route polyline, KPIs, AI verdict, RunCoach branding
5. Tap Share → iOS share sheet opent → "Save image" → check Photos app voor de PNG
6. Sluit popup, open app opnieuw → popup verschijnt NIET (al gemarkeerd)
7. Open dezelfde training-day detail → tap "Share this run" → zelfde card opent on-demand
8. Voer een treadmill-run uit (of mock route=null) → popup verschijnt met no-route variant
9. Switch app naar Engels → herhaal 3-4, check labels in EN
10. Test op iPhone met 3GB RAM (12 mini) — geen out-of-memory crash bij export
11. Marathon-test: importeer een ~42km run met ~3000 GPS-punten, controleer of polyline-simplificatie het terugbrengt en de render fluid is

## Deferred / V2 ideas

- Square (1:1) variant naast 9:16
- Direct Strava share button (via Strava deeplink) i.p.v. share sheet
- Privacy-zones: maskeer start/end binnen X meter van een opgegeven adres
- Weekly summary card (combine 5-7 runs in één visual)
- PR card: "Nieuw 5km PR — 22:14"
- Race-day card: speciaal layout met goal vs actual
- Card-template kiezen (3-4 designs, A/B test welke shareability geeft)
- Animated GIF/video export voor TikTok / Instagram Reels
