# Dashboard "Recent runs" section — design

**Date:** 2026-06-10
**Status:** approved (Erwin, 2026-06-10)

## Goal

Show the runner's recent runs on the dashboard — linked to a training day or not:

- **Unlinked** runs render with a blue plus icon; tapping opens the existing
  "Koppel aan training" sheet (`unplanned_run_sheet.dart`).
- **Linked** runs show the compliance score once AI analysis is available;
  tapping navigates to the training-day detail screen.

Mockup: compact rows with a leading icon, run name, `day · pace · duration`
subtitle, and the distance (km, italic) on the right. Eyebrow header
"RECENT RUNS" with a "See all" link.

## Decisions (Erwin)

| Question | Decision |
|---|---|
| Compliance display | **Score in the icon slot** — leading icon becomes a colored circle (green/gold/red via `ComplianceColors.forScore10`) containing the 0–10 score (e.g. "8.2"). No analysis yet → default gold mark. |
| "See all" | Navigates to the **Schedule tab** (`/schedule`). No new screen. |
| Count | **5** most recent runs. |
| Tap on linked run | **Training-day detail** (`/schedule/day/{id}`). |
| Data source | **Extend `GET /dashboard`** with a `recent_runs` array (approach A — one round-trip, refresh-after-link works via the existing `planVersionProvider` watch). |

## Backend

`DashboardController` adds a `recent_runs` array to the response (both the
no-goal and active-goal branches, for shape stability):

- Query: the user's 5 newest `wearable_activities` rows, `type` in
  `WearableActivity::RUN_TYPES`, ordered by `start_date` desc, with
  `trainingResults` eager-loaded (avoid N+1).
- Entry shape (nested, so Flutter reuses `WearableActivitySummary` as-is):

```json
{
  "run": { /* same shape as TrainingScheduleController::unplannedRunPayload */ },
  "training_day_id": 123,        // null when not linked
  "compliance_score": 8.2        // null when not linked OR not yet scored
}
```

- `training_day_id` / `compliance_score` come from the activity's first
  `TrainingResult` (an activity has at most one in practice).
- **Shared payload helper:** the summary shape currently lives in
  `TrainingScheduleController::unplannedRunPayload`. Move it to
  `WearableActivity::toSummaryPayload(): array` on the model and use it from
  both controllers so the shapes can't drift.

## Flutter

### Model

- New Freezed model `RecentRun` (`features/dashboard/models/`):
  `{ run: WearableActivitySummary, trainingDayId: int?, complianceScore: double? }`
  (`compliance_score` via `toDoubleOrNull` — MySQL decimals arrive as strings).
- `DashboardData` gains `@JsonKey(name: 'recent_runs') @Default([]) List<RecentRun> recentRuns`.

### UI

New `_RecentRunsSection` in `dashboard_screen.dart`, rendered inside
`_DashboardContent` between `_ThisWeekCard` and `_WeeksMatrixCard` (so it only
appears when there is an active goal — which also guarantees `goal.id` for the
link sheet):

- Header row: eyebrow "RECENT RUNS" (l10n `dashRecentRuns`) + trailing
  "See all" link (l10n `dashRecentRunsSeeAll`) → `context.go('/schedule')`.
- Row layout per mockup: leading 40×40 icon slot, bold title (run `name`,
  fallback l10n "Run"), subtitle `EEE · M:SS/km · MM:SS`, trailing italic
  distance (km, 1 decimal) with a small muted " KM" suffix.
- **Icon slot = status:**
  - Linked + `complianceScore != null` → circle tinted by
    `ComplianceColors.forScore10(score)` with the score (1 decimal) inside.
  - Linked, score still null (analysis pending) → default gold mark
    (same icon style as the mockup rows).
  - Unlinked → blue circle (`AppColors.offPlan`) with a white
    `Icons.add_rounded`, mirroring the off-plan tiles in the weekly plan.
- **Tap:**
  - Linked → `context.go('/schedule/day/{trainingDayId}')`.
  - Unlinked → `showUnplannedRunSheet(context, run: r.run, goalId: goal.id)`.
- Section hidden entirely when `recentRuns` is empty.

### Refresh

`linkUnplannedRunProvider.link()` already bumps `planVersionProvider`, and
`dashboardProvider` watches it — after linking via the sheet the dashboard
refetches automatically. No new wiring.

### l10n

New keys in `app_en.arb` + `app_nl.arb`: `dashRecentRuns`
("Recent runs" / "Recente runs"), `dashRecentRunsSeeAll`
("See all" / "Bekijk alles"), plus a fallback run title if no suitable key
exists yet.

## Testing

- **Backend** (`tests/Feature/DashboardTest.php`): `recent_runs` present;
  linked run carries `training_day_id` + `compliance_score`; unlinked run has
  nulls; capped at 5; non-run activity types excluded; ordered newest-first.
- **Flutter**: `flutter analyze` + `flutter test` (model parse covered by
  build_runner output; section behaviour is straightforward composition).

## Out of scope

- A dedicated "all runs" screen (See all goes to the Schedule tab).
- Compliance on the schedule's off-plan tiles (unchanged).
- Android / other wearable sources (data layer already source-agnostic).
