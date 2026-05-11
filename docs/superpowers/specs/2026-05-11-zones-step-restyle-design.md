# Onboarding — restyle and reposition the zones step

**Status:** draft
**Author:** Erwin + Claude
**Date:** 2026-05-11

## Problem

`/onboarding/zones` sits as the second screen of onboarding, immediately after `/onboarding/connect-health`. A beginner runner — someone who's never heard of "training zones" or "max HR" — gets a 5-row bpm table as their second-ever interaction with the app. They tap "Looks right" without understanding what they're confirming, or worse, bounce off thinking the app is for people who already know this stuff.

The screen ALSO triggers an automatic DOB prompt when the deriver couldn't compute (no HealthKit DOB, no stored DOB), but that prompt arrives mid-screen as a modal dialog over already-confusing copy. The intended flow ("just enter your birth date and tap through") is buried.

## Goal

1. Move `/onboarding/zones` to AFTER `/onboarding/overview` (the editable baseline screen we just built) so the runner has already had two softer touch-points before they see anything HR-related.
2. Restyle the zones screen so DOB is the *primary* element for runners without wearable HR data. Beginners can pick a date and continue — they never see a bpm table unless they tap "Show zones (advanced)".
3. Keep the existing rich confirmation copy for wearable users who DO have HR-data-derived zones — that's a meaningful "we learned this about you" moment for them, not a slap in the face.

## Non-goals

- **Removing the zones step entirely** — HR zones drive compliance scoring + pace-adjustment notifications. We still need them set, and we still want the runner to acknowledge that the app is using them.
- **Changing the underlying derivation** — `HeartRateZoneDeriver` (backend) and the Tanaka/Karvonen logic stay as-is.
- **Removing `users.heart_rate_zones_source = 'default'`** — fallback path stays for users who somehow get through onboarding without DOB AND without HR data. We just push the DOB-or-default decision into the user's hands more clearly.
- **Onboarding-only edits to the zones model** — out of scope. Edit-from-menu (`HeartRateZonesSheet`) continues unchanged.

## Design

### New flow

```
Before:
  /onboarding/connect-health → /onboarding/zones → /onboarding/overview → /onboarding/form → /onboarding/generating

After:
  /onboarding/connect-health → /onboarding/overview → /onboarding/zones → /onboarding/form → /onboarding/generating
```

The zones step becomes the *third* user-facing screen, sitting between baseline (km/pace) and goals (form). It feels like part of the "your fitness profile" cluster instead of an isolated warm-up obstacle.

### Three states on the zones screen

The screen auto-picks one of three states on mount, based on the user's data:

| State | Trigger | Primary element | CTA |
|---|---|---|---|
| **A — HR-confirmed** | `user.heart_rate_zones_source` is `manual`, `derived_empirical`, OR `derived_age` with `DerivedZones.wasCorrected == true` (i.e. there's an empirical signal mixed in) | bpm table (`HrZonesReadonlyList`) + rich subtitle citing samples / runs / age | "Looks right" enabled |
| **B — DOB known, no HR signal** | `user.date_of_birth` non-null AND source is `derived_age` without `wasCorrected` | Big tappable DOB row + helper text + collapsed "Show zones (advanced)" link | "Continue" enabled immediately |
| **C — No DOB** | `user.date_of_birth` is null AND source is `default` | DOB picker prompt (auto-opens on first frame) | Disabled until DOB picked; after pick → auto-derive → transitions to state B |

State detection lives in the screen widget, not the router. The router just routes to `/onboarding/zones` — the screen reads `user.dateOfBirth` + `user.heartRateZonesSource` + the latest `DerivedZones` (carried via a Riverpod provider, see below) and picks its body.

### State A body (unchanged from today)

```
┌────────────────────────────────────────┐
│   Your training zones                  │
│                                        │
│   Based on your age and your hardest   │
│   recent runs, your max heart rate     │
│   looks to be around 191 bpm.          │
│   We've split that into 5 training     │
│   zones.                               │
│                                        │
│   Zone 1   < 115 bpm                   │
│   Zone 2   115 – 134 bpm               │
│   Zone 3   134 – 154 bpm               │
│   Zone 4   154 – 173 bpm               │
│   Zone 5   173+ bpm                    │
│                                        │
│           [ Looks right ]              │
│            Edit zones                  │
└────────────────────────────────────────┘
```

### State B body (DOB-first)

```
┌────────────────────────────────────────┐
│   Your training zones                  │
│                                        │
│   We use your age to estimate          │
│   heart-rate ranges for training       │
│   feedback. You can fine-tune later    │
│   from the menu.                       │
│                                        │
│   ┌──────────────────────────────┐     │
│   │  Date of birth               │     │
│   │  June 15, 1990            ›  │     │
│   └──────────────────────────────┘     │
│                                        │
│   ▸ Show zones (advanced)              │
│                                        │
│           [ Continue ]                 │
└────────────────────────────────────────┘
```

Tapping the DOB row opens `showBirthDatePickerSheet` (already exists), prefilled with the current value. On confirm, re-fires `deriveHeartRateZones` and updates the row label. The "Show zones (advanced)" link expands into `HrZonesReadonlyList` + an "Edit zones" link that opens `HeartRateZonesSheet`.

### State C body (no DOB)

```
┌────────────────────────────────────────┐
│   Your training zones                  │
│                                        │
│   To estimate your heart-rate ranges,  │
│   we just need your birth date. It     │
│   gives us a rough max HR — accurate   │
│   enough for daily training and easy   │
│   to fine-tune later.                  │
│                                        │
│   ┌──────────────────────────────┐     │
│   │  Pick your birth date     ›  │     │
│   └──────────────────────────────┘     │
│                                        │
│           [ Continue ]   (disabled)    │
└────────────────────────────────────────┘
```

DOB-picker sheet auto-opens once on first frame (post-frame callback). If the user cancels, the screen stays in state C with CTA disabled. The user can re-trigger by tapping the DOB row.

After DOB is picked, the screen calls `deriveHeartRateZones`, refreshes the user, and transitions to state B. CTA becomes enabled.

### Passing the `DerivedZones` between screens

Currently `OnboardingConnectHealthScreen` passes `DerivedZones?` via GoRouter `extra: derivedZones` directly into `/onboarding/zones`. After the reorder, connect-health navigates to `/onboarding/overview`, and the result needs to survive the in-between screen.

Solution: store the latest derive result in a Riverpod provider — `onboardingDerivedZonesProvider` (`StateProvider<DerivedZones?>` in `lib/features/onboarding/providers/`). Connect-health sets it after the derive call. Zones screen reads it on mount. Overview ignores it entirely (doesn't touch zones).

On cold-start / deep-link / re-onboarding the provider is null, the zones screen falls back to `user.heartRateZonesSource` for state-detection, and subtitle copy is generic (no "based on N runs" claim). That matches today's "deep-link to zones with no extra" behavior.

### Router changes

| Change | File |
|---|---|
| `/onboarding` redirect: `kIsWeb ? '/onboarding/zones' : '/onboarding/connect-health'` → `kIsWeb ? '/onboarding/overview' : '/onboarding/connect-health'` | `app/lib/router/app_router.dart` |
| Web-skip for `/onboarding/connect-health`: `'/onboarding/zones'` → `'/onboarding/overview'` | same file |
| Connect-health forward navigation: `context.go('/onboarding/zones', extra: derivedZones)` → `ref.read(onboardingDerivedZonesProvider.notifier).state = derivedZones; context.go('/onboarding/overview');` | `onboarding_connect_health_screen.dart` |
| Connect-health "Continue without syncing" path: `'/onboarding/form'` → `'/onboarding/overview'` (currently skips overview AND zones entirely, which is a regression we should fix while we're here) | same file |
| Overview submit-navigation: `context.push('/onboarding/form')` → `context.push('/onboarding/zones')` | `onboarding_overview_screen.dart` |
| Zones screen "Looks right" / "Continue": `context.go('/onboarding/overview')` → `context.go('/onboarding/form')` | `onboarding_zones_screen.dart` |
| Remove the `state.extra` pass-through in the `/onboarding/zones` route definition (no longer needed — provider holds the data) | `app/lib/router/app_router.dart` |

### Screen refactor — `onboarding_zones_screen.dart`

The existing `_Body` and `_UnavailableBody` get reorganized into three explicit state widgets:

- **`_HrConfirmedBody`** — current `_Body` with title text changed from "Your heart rate zones" → "Your training zones".
- **`_DobKnownBody`** — new. Big DOB row + helper + collapsed advanced section.
- **`_NoDobBody`** — new. DOB-picker prompt + disabled CTA. Auto-opens picker via post-frame callback (replaces current "_maybePromptForAge" logic, which is repurposed).

State picker (top of `build()`):

```dart
final user = ref.watch(authProvider).value;
final source = _result?.source ?? user?.heartRateZonesSource ?? 'default';
final dob = user?.dateOfBirth;
final hasHrSignal = source == 'manual'
    || source == 'derived_empirical'
    || (source == 'derived_age' && (_result?.wasCorrected ?? false));

if (hasHrSignal && user?.heartRateZones != null) {
  return _HrConfirmedBody(...);
}
if (dob != null) {
  return _DobKnownBody(dob: dob, onPickDob: _pickDob, ...);
}
return _NoDobBody(onPickDob: _pickDob, ...);
```

`_pickDob()` is the existing logic (cached as `_maybePromptForAge`'s body) — opens the picker, derives zones, refreshes user. After it runs, `setState` triggers re-evaluation and the screen drops into state B (DOB-known).

The auto-prompt-on-empty becomes specific to state C: only auto-opens when DOB is null AND `_didAutoPrompt == false`. If the user cancels, no loop.

### Title copy change

"Your heart rate zones" → "Your training zones" everywhere on this screen. The word "zones" is unavoidable (it's a real domain term and the existing menu sheet uses it too), but "training" lands softer than "heart rate" for someone who's never heard of either.

### What the runner sees end-to-end

**Beginner (no wearable, no DOB):**
```
1. /onboarding/connect-health  — skip via "Continue without syncing"
2. /onboarding/overview        — enters km/wk + easy pace
3. /onboarding/zones (state C) — DOB picker auto-opens → pick → transitions to state B → tap Continue
4. /onboarding/form            — picks goals
5. /onboarding/generating
```

Wears 3 friction-tap-Continue, never sees a bpm table.

**Wearable user (full HR history):**
```
1. /onboarding/connect-health  — syncs activities + derives zones empirically
2. /onboarding/overview        — sees prefilled km/wk + easy pace (locked)
3. /onboarding/zones (state A) — sees zones table + "Based on your last 23 runs…"
4. /onboarding/form            — picks goals
5. /onboarding/generating
```

Same number of steps but each screen carries meaningful info.

**Returning user with DOB but no fresh wearable data:**
```
3. /onboarding/zones (state B) — DOB row prefilled + collapsed advanced section
```

### Edge cases

| Case | Behaviour |
|---|---|
| User picks DOB in state C, derive call fails (network blip) | Stay in state C, show inline error under the DOB row. Continue stays disabled. Retry by tapping DOB again. |
| User in state B taps DOB row to change birth year | Re-derives, zones update. Subtle visual flash on the bpm list if expanded; nothing else. |
| Deep-link to `/onboarding/zones` from a re-onboarding scenario | `onboardingDerivedZonesProvider` is null. Falls back to `user.heartRateZonesSource` for state detection; subtitle is generic. |
| User cancels DOB picker in state C | State stays C. CTA disabled. No auto-loop (`_didAutoPrompt = true` after first open regardless of outcome). |
| User in state A taps "Edit zones" → manually overrides to bpm values they prefer | Source flips to `manual`. State remains A on re-render (manual is HR-confirmed). |
| User on web (no HealthKit) | Web-skip routes to `/onboarding/overview`. Zones screen still shows in flow order — they'll likely land in state B (dev seed sets DOB) or C (production web users without a seed). |

## Files

### Flutter

| File | Change |
|---|---|
| `app/lib/router/app_router.dart` | Reorder routes, update web-skip redirect, drop `state.extra` for `/onboarding/zones` |
| `app/lib/features/onboarding/providers/onboarding_derived_zones_provider.dart` | **new** — `StateProvider<DerivedZones?>` shared between connect-health and zones screen |
| `app/lib/features/onboarding/screens/onboarding_connect_health_screen.dart` | Set provider before navigating; forward target = `/onboarding/overview`; fix "Continue without syncing" to also go to overview |
| `app/lib/features/onboarding/screens/onboarding_overview_screen.dart` | Submit-success navigation = `/onboarding/zones` (was `/onboarding/form`) |
| `app/lib/features/onboarding/screens/onboarding_zones_screen.dart` | Refactor into 3 state-bodies; title → "Your training zones"; "Looks right" forwards to `/onboarding/form` |

### Tests

| File | Coverage |
|---|---|
| `app/test/features/onboarding/onboarding_zones_screen_test.dart` (**new**) | State A (zones-table render with rich subtitle), state B (DOB row + collapsed advanced), state C (auto-opened picker + CTA disabled until DOB picked) |
| `app/test/features/onboarding/onboarding_overview_screen_test.dart` (extend) | Submit navigates to `/onboarding/zones` (was `/onboarding/form`) |

No backend changes. Migrations / endpoints / services all untouched.

## Testing

- Widget tests cover all three zones-screen states + the overview-screen forward navigation.
- Manual smoke test:
  1. Fresh dev user (`DevOnboardingSeeder` resets DOB to known value) → connect-health skip → overview fill-in → zones (state B with DOB prefilled) → form.
  2. Wipe DOB via tinker (`User::find(1)->update(['date_of_birth' => null, 'heart_rate_zones_source' => 'default']);`) → connect-health skip → overview → zones (state C → auto-open picker → pick → state B → Continue).
  3. Existing wearable seeder → connect-health → overview → zones (state A with empirical subtitle) → form.

## Migration / rollout

No DB migration. No backend changes. Flutter-only restructure. Existing users in production are past onboarding; this only affects the first-onboarding path for new users.
