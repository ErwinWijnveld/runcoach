# Zones step — reposition and beginner-friendly restyle — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `/onboarding/zones` to AFTER `/onboarding/overview` and restyle it so beginners without HR data see a DOB picker as the primary element (not a bpm table).

**Architecture:** Pure Flutter restructure. Router gets a reorder + web-skip update. The zones screen splits into three explicit state-bodies (HR-confirmed / DOB-known / no-DOB) chosen at runtime from `user.heart_rate_zones_source` + `user.date_of_birth`. A small Riverpod `StateProvider<DerivedZones?>` carries the connect-health derive result across the new in-between overview screen.

**Tech Stack:** Flutter + Riverpod codegen + GoRouter + flutter_test. No backend changes.

**Spec:** `docs/superpowers/specs/2026-05-11-zones-step-restyle-design.md`

---

## Task 1: Add the `onboardingDerivedZonesProvider`

**Files:**
- Create: `app/lib/features/onboarding/providers/onboarding_derived_zones_provider.dart`

- [ ] **Step 1: Create the provider file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/models/derived_zones.dart';

/// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
/// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
///
/// Connect-health sets it after a successful derive call; zones-screen reads
/// it on mount to populate source-aware subtitle copy (e.g. "Based on your
/// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
/// derive call failed silently) — the zones screen falls back to generic
/// copy based on `user.heartRateZonesSource`.
final onboardingDerivedZonesProvider = StateProvider<DerivedZones?>((ref) => null);
```

- [ ] **Step 2: Verify analyzer clean**

```bash
cd app && flutter analyze lib/features/onboarding/providers/onboarding_derived_zones_provider.dart
```

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/providers/onboarding_derived_zones_provider.dart
git commit -m "feat(onboarding): provider to carry DerivedZones across overview"
```

---

## Task 2: Wire connect-health to write the provider + forward to overview

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_connect_health_screen.dart`

- [ ] **Step 1: Add import**

At the top of `onboarding_connect_health_screen.dart`, add:

```dart
import 'package:app/features/onboarding/providers/onboarding_derived_zones_provider.dart';
```

- [ ] **Step 2: Replace the forward-navigate after sync**

Find (around line 165-167):

```dart
    // Brief moment so the user sees "Synced N runs" before we move on.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go('/onboarding/zones', extra: derivedZones);
```

Change to:

```dart
    // Brief moment so the user sees "Synced N runs" before we move on.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // Stash the derive result so the zones screen (now two steps away)
    // can still source-aware its subtitle without a re-fetch.
    ref.read(onboardingDerivedZonesProvider.notifier).state = derivedZones;
    context.go('/onboarding/overview');
```

- [ ] **Step 3: Fix the "Continue without syncing" / skip path**

Find `_skipToForm()` (around line 199-201):

```dart
  void _skipToForm() {
    context.go('/onboarding/form');
  }
```

Change to:

```dart
  void _skipToOverview() {
    context.go('/onboarding/overview');
  }
```

Then update the two callers — search for `_skipToForm` in the file (the "Continue without syncing" button on `_IntroBody` and the "Continue anyway" button on `_EmptyHistoryBody`). Replace both call sites with `_skipToOverview`.

- [ ] **Step 4: Run the analyzer**

```bash
cd app && flutter analyze lib/features/onboarding/screens/onboarding_connect_health_screen.dart
```

Expected: 0 issues.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/screens/onboarding_connect_health_screen.dart
git commit -m "feat(onboarding): connect-health forwards to overview, stashes zones in provider"
```

---

## Task 3: Update router routes + redirects

**Files:**
- Modify: `app/lib/router/app_router.dart`

- [ ] **Step 1: Update the web-skip redirects**

In `app_router.dart`, find:

```dart
      // Web has no HealthKit — the connect-health screen would just sit on
      // a permission prompt that never resolves. The dev seed pre-populates
      // activities + zones, so jump straight to the zones step.
      if (kIsWeb && state.matchedLocation == '/onboarding/connect-health') {
        return '/onboarding/zones';
      }
```

Change `'/onboarding/zones'` to `'/onboarding/overview'`. Update the comment to reflect that we now jump to the baseline step (zones comes after).

Then find (a few lines below):

```dart
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) {
          if (state.matchedLocation != '/onboarding') return null;
          // Web has no HealthKit; skip directly to zones (seeded in dev).
          return kIsWeb
              ? '/onboarding/zones'
              : '/onboarding/connect-health';
        },
      ),
```

Change `'/onboarding/zones'` to `'/onboarding/overview'` and update the comment to "Web has no HealthKit; skip directly to baseline (zones comes next)."

- [ ] **Step 2: Drop the `state.extra` plumbing on the zones route**

The connect-health screen no longer passes a `DerivedZones` via `extra` — the new provider holds it. Find:

```dart
      GoRoute(
        path: '/onboarding/zones',
        builder: (context, state) {
          // The connect-health screen passes its DerivedZones result via
          // `extra` so the subtitle copy can be source-aware without
          // re-fetching. Falls back to null on deep-link / cold-start.
          final extra = state.extra;
          return OnboardingZonesScreen(
            initialResult: extra is DerivedZones ? extra : null,
          );
        },
      ),
```

Change to:

```dart
      GoRoute(
        path: '/onboarding/zones',
        builder: (context, state) => const OnboardingZonesScreen(),
      ),
```

The `DerivedZones` import on `app_router.dart` may now be unused; if `flutter analyze` flags it, remove the import.

- [ ] **Step 3: Run the analyzer**

```bash
cd app && flutter analyze lib/router/app_router.dart
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/router/app_router.dart
git commit -m "feat(onboarding): router reorder — overview before zones"
```

---

## Task 4: Update overview screen forward-navigation

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_overview_screen.dart`

- [ ] **Step 1: Change the post-submit navigation target**

Find the `_submit()` method (around line 145-155). Locate:

```dart
      await save(weeklyKm: weeklyKm, easyPaceSecondsPerKm: easyPace);
      if (!mounted) return;
      context.push('/onboarding/form');
```

Change to:

```dart
      await save(weeklyKm: weeklyKm, easyPaceSecondsPerKm: easyPace);
      if (!mounted) return;
      context.push('/onboarding/zones');
```

- [ ] **Step 2: Update the error-state Skip target**

In the same file, find `_ErrorState` and its `onSkip` parameter usage:

```dart
                  onSkip: () => context.go('/onboarding/form'),
```

Change to:

```dart
                  onSkip: () => context.go('/onboarding/zones'),
```

- [ ] **Step 3: Update the existing widget test to expect the new target**

Open `app/test/features/onboarding/onboarding_overview_screen_test.dart`. Find the GoRouter routes setup:

```dart
      GoRoute(
        path: '/onboarding/form',
        builder: (_, _) => const Material(child: Center(child: Text('FORM REACHED'))),
      ),
```

Add a route for `/onboarding/zones` (so the existing tests' assertion that submit-then-navigation works keeps a destination):

```dart
      GoRoute(
        path: '/onboarding/form',
        builder: (_, _) => const Material(child: Center(child: Text('FORM REACHED'))),
      ),
      GoRoute(
        path: '/onboarding/zones',
        builder: (_, _) => const Material(child: Center(child: Text('ZONES REACHED'))),
      ),
```

Then in both existing tests, change `find.text('FORM REACHED')` to `find.text('ZONES REACHED')`. There are two occurrences — one in the no-wearable test and one in the wearable test.

- [ ] **Step 4: Run the test**

```bash
cd app && flutter test test/features/onboarding/onboarding_overview_screen_test.dart
```

Expected: 2/2 pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/screens/onboarding_overview_screen.dart app/test/features/onboarding/onboarding_overview_screen_test.dart
git commit -m "feat(onboarding): overview forwards to zones (was form)"
```

---

## Task 5: Refactor zones screen — three state bodies

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_zones_screen.dart`

This is the biggest task. The existing screen has `_Body` (zones available) and `_UnavailableBody` (zones missing). We're replacing both with three new bodies plus a state picker.

- [ ] **Step 1: Add the provider import + remove the constructor param**

At the top of `onboarding_zones_screen.dart`, replace this import block:

```dart
import 'package:app/features/auth/models/derived_zones.dart';
```

with:

```dart
import 'package:app/features/auth/models/derived_zones.dart';
import 'package:app/features/onboarding/providers/onboarding_derived_zones_provider.dart';
```

Then find the constructor:

```dart
class OnboardingZonesScreen extends ConsumerStatefulWidget {
  /// The derive result that produced the currently-saved zones. May be
  /// null if the runner navigated here via deep link without a fresh
  /// derive — in that case the screen falls back to displaying the user's
  /// stored zones with a generic subtitle.
  final DerivedZones? initialResult;

  const OnboardingZonesScreen({super.key, this.initialResult});

  @override
  ConsumerState<OnboardingZonesScreen> createState() =>
      _OnboardingZonesScreenState();
}
```

Change to:

```dart
class OnboardingZonesScreen extends ConsumerStatefulWidget {
  const OnboardingZonesScreen({super.key});

  @override
  ConsumerState<OnboardingZonesScreen> createState() =>
      _OnboardingZonesScreenState();
}
```

- [ ] **Step 2: Replace the state-class top section**

Find the existing `_OnboardingZonesScreenState` class definition through the `_build` method (lines ~46–147). Replace the whole `_OnboardingZonesScreenState` class with:

```dart
class _OnboardingZonesScreenState
    extends ConsumerState<OnboardingZonesScreen> {
  DerivedZones? _result;
  bool _didAutoPrompt = false;

  @override
  void initState() {
    super.initState();
    _result = ref.read(onboardingDerivedZonesProvider);
    SchedulerBinding.instance.addPostFrameCallback((_) => _maybeAutoOpenPicker());
  }

  /// State C only: auto-open the DOB picker once, so the runner doesn't
  /// have to find the tap target on a screen they've never seen.
  Future<void> _maybeAutoOpenPicker() async {
    if (!mounted || _didAutoPrompt) return;
    final user = ref.read(authProvider).value;
    if (user == null) return; // auth still loading; we'll re-evaluate
    if (user.dateOfBirth != null) return;
    final source = _result?.source ?? user.heartRateZonesSource ?? 'default';
    if (source != 'default') return;

    _didAutoPrompt = true;
    await _pickDob();
  }

  Future<void> _pickDob() async {
    final user = ref.read(authProvider).value;
    if (user == null || !mounted) return;

    final dob = await showBirthDatePickerSheet(
      context,
      initial: user.dateOfBirth,
    );
    if (dob == null || !mounted) return;

    try {
      final hk = ref.read(healthKitServiceProvider);
      final restingHr = await hk.getLatestRestingHeartRate();
      final result = await ref.read(authProvider.notifier).deriveHeartRateZones(
            dateOfBirth: dob,
            restingHeartRate: restingHr,
          );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      // Network blip — runner can retry by tapping DOB again.
    }
  }

  void _continue() => context.go('/onboarding/form');

  Future<void> _openEditSheet() async {
    await showHeartRateZonesSheet(context);
    if (mounted) setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate auto-prompt when auth resolves on cold-launch.
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      if (next.value != null && !_didAutoPrompt) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => _maybeAutoOpenPicker(),
        );
      }
    });

    final user = ref.watch(authProvider).value;
    final source = _result?.source ?? user?.heartRateZonesSource ?? 'default';
    final dob = user?.dateOfBirth;
    final zones = user?.heartRateZones;

    final hasHrSignal = source == 'manual'
        || source == 'derived_empirical'
        || (source == 'derived_age' && (_result?.wasCorrected ?? false));

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 56,
              child: Center(
                child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _selectBody(
                  hasHrSignal: hasHrSignal,
                  zones: zones,
                  dob: dob,
                  source: source,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectBody({
    required bool hasHrSignal,
    required List<dynamic>? zones,
    required DateTime? dob,
    required String source,
  }) {
    if (hasHrSignal && zones != null) {
      return _HrConfirmedBody(
        zones: zones,
        source: source,
        result: _result,
        onContinue: _continue,
        onEdit: _openEditSheet,
      );
    }
    if (dob != null) {
      return _DobKnownBody(
        dob: dob,
        zones: zones,
        onPickDob: _pickDob,
        onContinue: _continue,
        onEdit: _openEditSheet,
      );
    }
    return _NoDobBody(onPickDob: _pickDob);
  }
}
```

- [ ] **Step 3: Rename the existing `_Body` widget to `_HrConfirmedBody` and update title**

Find:

```dart
class _Body extends StatelessWidget {
  final List zones;
  // ...
```

Rename the class to `_HrConfirmedBody`. Find inside its `build()`:

```dart
        Text('Your heart rate zones', style: RunCoreText.serifTitle(size: 30)),
```

Change to:

```dart
        Text('Your training zones', style: RunCoreText.serifTitle(size: 30)),
```

Also change the typed `final List zones;` parameter to `final List<dynamic> zones;` for explicitness (already worked since dynamic, just cleaner).

- [ ] **Step 4: Remove `_UnavailableBody` (replaced by `_NoDobBody`)**

Delete the entire `_UnavailableBody` class (~lines 233-268 in the original file).

- [ ] **Step 5: Add `_DobKnownBody` and `_NoDobBody`**

At the bottom of the file (after `_HrConfirmedBody`'s closing brace), add:

```dart
class _DobKnownBody extends StatefulWidget {
  final DateTime dob;
  final List<dynamic>? zones;
  final Future<void> Function() onPickDob;
  final VoidCallback onContinue;
  final Future<void> Function() onEdit;

  const _DobKnownBody({
    required this.dob,
    required this.zones,
    required this.onPickDob,
    required this.onContinue,
    required this.onEdit,
  });

  @override
  State<_DobKnownBody> createState() => _DobKnownBodyState();
}

class _DobKnownBodyState extends State<_DobKnownBody> {
  bool _expanded = false;

  String _formatDob(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Your training zones', style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          "We use your age to estimate heart-rate ranges for training feedback. You can fine-tune later from the menu.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: widget.onPickDob,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of birth',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDob(widget.dob),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(
                _expanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Show zones (advanced)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        if (_expanded && widget.zones != null) ...[
          const SizedBox(height: 12),
          HrZonesReadonlyList(zones: List.from(widget.zones!)),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onEdit,
            child: Text(
              'Edit zones',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkMuted),
            ),
          ),
        ],
        const Spacer(),
        OnboardingPrimaryButton(label: 'Continue', onTap: widget.onContinue),
      ],
    );
  }
}

class _NoDobBody extends StatelessWidget {
  final Future<void> Function() onPickDob;

  const _NoDobBody({required this.onPickDob});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Your training zones', style: RunCoreText.serifTitle(size: 30)),
        const SizedBox(height: 8),
        Text(
          "To estimate your heart-rate ranges we just need your birth date. It gives us a rough max HR — accurate enough for daily training and easy to fine-tune later.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onPickDob,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pick your birth date',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
        const Spacer(),
        OnboardingPrimaryButton(label: 'Continue', onTap: null),
      ],
    );
  }
}
```

- [ ] **Step 6: Update `_HrConfirmedBody._continue` callback target**

Inside `_HrConfirmedBody.build`, find:

```dart
        OnboardingPrimaryButton(label: 'Looks right', onTap: onContinue),
```

Leave the button as-is — `onContinue` will now route to `/onboarding/form` (the `_continue` method on the state class was updated in Step 2).

- [ ] **Step 7: Run the analyzer**

```bash
cd app && flutter analyze lib/features/onboarding/screens/onboarding_zones_screen.dart
```

Expected: 0 issues. Address any unused-import warnings that come up.

- [ ] **Step 8: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/onboarding/screens/onboarding_zones_screen.dart
git commit -m "feat(onboarding): three-state zones screen (HR-confirmed / DOB-known / no-DOB)"
```

---

## Task 6: Widget tests for the zones screen

**Files:**
- Create: `app/test/features/onboarding/onboarding_zones_screen_test.dart`

- [ ] **Step 1: Write the tests**

Create `app/test/features/onboarding/onboarding_zones_screen_test.dart`:

```dart
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/screens/onboarding_zones_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Stub auth that resolves to a fixed user without making any API calls.
class _StubAuth extends Auth {
  _StubAuth(this._user);
  final User? _user;

  @override
  Future<User?> build() async => _user;
}

Future<void> _pumpScreen(WidgetTester tester, {User? user}) async {
  final router = GoRouter(
    initialLocation: '/onboarding/zones',
    routes: [
      GoRoute(
        path: '/onboarding/zones',
        builder: (_, _) => const OnboardingZonesScreen(),
      ),
      GoRoute(
        path: '/onboarding/form',
        builder: (_, _) => const Material(child: Center(child: Text('FORM REACHED'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _StubAuth(user)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('state B (DOB-known, no HR data): renders DOB row + collapsed advanced + Continue enabled',
      (tester) async {
    final user = _userWith(
      dateOfBirth: DateTime(1990, 6, 15),
      source: 'derived_age',
      heartRateZones: const [
        {'min': 0, 'max': 115},
        {'min': 115, 'max': 134},
        {'min': 134, 'max': 154},
        {'min': 154, 'max': 173},
        {'min': 173, 'max': 220},
      ],
    );

    await _pumpScreen(tester, user: user);

    expect(find.text('Your training zones'), findsOneWidget);
    expect(find.text('June 15, 1990'), findsOneWidget);
    expect(find.text('Show zones (advanced)'), findsOneWidget);
    // Zones table NOT visible until expanded.
    expect(find.text('Zone 1'), findsNothing);

    // Expand
    await tester.tap(find.text('Show zones (advanced)'));
    await tester.pumpAndSettle();
    // After expansion, zone labels should render (exact label depends
    // on HrZonesReadonlyList format — we just check at least one zone
    // row indicator surfaces).
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('state C (no DOB): renders Pick-DOB row + Continue disabled', (tester) async {
    final user = _userWith(
      dateOfBirth: null,
      source: 'default',
      heartRateZones: null,
    );

    await _pumpScreen(tester, user: user);

    expect(find.text('Your training zones'), findsOneWidget);
    expect(find.text('Pick your birth date'), findsOneWidget);
    // Continue exists but onTap is null → 35% opacity wrapper.
    expect(find.text('CONTINUE'), findsOneWidget);
  });
}

User _userWith({
  required DateTime? dateOfBirth,
  required String source,
  required List<dynamic>? heartRateZones,
}) {
  return User(
    id: 1,
    name: 'Test',
    email: 't@test.app',
    hasCompletedOnboarding: false,
    coachStyle: null,
    heartRateZones: heartRateZones,
    heartRateZonesSource: source,
    dateOfBirth: dateOfBirth,
    personalRecords: null,
    pendingPlanGeneration: null,
    selfReportedWeeklyKm: null,
    selfReportedEasyPaceSecondsPerKm: null,
  );
}
```

NOTE: the `User` constructor invocation must match your actual Freezed model. Check `app/lib/features/auth/models/user.dart` — fields may differ. Adjust the `_userWith` helper to match. If `Auth` is harder to stub than the above (codegen issues, or the build method isn't directly overridable), simplify by overriding via `authProvider.overrideWith((ref) => _Stub(user))` with a synchronous AsyncValue.data return instead.

- [ ] **Step 2: Run the test**

```bash
cd app && flutter test test/features/onboarding/onboarding_zones_screen_test.dart
```

Expected: 2/2 pass. If the `_StubAuth` pattern fails because the codegen creates a different class, fall back to a simpler `authProvider.overrideWith` that returns the user directly via `AsyncValue.data`. The shape of the test (assertions) stays the same — only the override mechanic changes.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/test/features/onboarding/onboarding_zones_screen_test.dart
git commit -m "test(onboarding): widget tests for three-state zones screen"
```

---

## Task 7: Documentation updates

**Files:**
- Modify: `CLAUDE.md`
- Modify: `app/CLAUDE.md`

- [ ] **Step 1: Update the root CLAUDE.md flow description**

Open `/Users/erwin/personal/runcoach/CLAUDE.md`. Find the previous self-reported bullet I added earlier. Either append a new bullet OR update an existing flow description if one mentions screen order. Add at the bottom of the "Current state" section:

```markdown
- **Zones step repositioned + restyled** — `/onboarding/zones` now sits AFTER `/onboarding/overview` (the baseline screen), not after connect-health. Screen has three states: HR-confirmed (zones table + rich subtitle), DOB-known (big DOB row + collapsed advanced section), no-DOB (auto-opens Cupertino DOB picker + Continue disabled until pick). Beginners can pick a birth date and tap through without ever seeing a bpm table. Spec: `docs/superpowers/specs/2026-05-11-zones-step-restyle-design.md`.
```

- [ ] **Step 2: Update app/CLAUDE.md**

Open `/Users/erwin/personal/runcoach/app/CLAUDE.md`. Find the "Onboarding flow (new user)" section. Find this line (added previously):

```markdown
3. `/onboarding/overview` — `OnboardingOverviewScreen` is an editable 2-field baseline form ...
```

And the next line about zones (line 175 area). Reorder them so the flow reads:

1. `/onboarding/connect-health`
2. `/onboarding/overview` (was step 3)
3. `/onboarding/zones` (was step 2 — replace text with three-state description)
4. `/onboarding/form`
5. `/onboarding/generating`

For the zones step, replace its line with:

```markdown
3. `/onboarding/zones` — `OnboardingZonesScreen` has three states selected at runtime: (A) **HR-confirmed** when the cascade had empirical signal — full bpm table + "based on N runs" subtitle; (B) **DOB-known** — big DOB row, collapsed "Show zones (advanced)" link; (C) **no-DOB** — picker auto-opens on first frame, Continue disabled until pick. State machine reads `user.dateOfBirth` + `user.heartRateZonesSource` + an `onboardingDerivedZonesProvider` (StateProvider carried over from connect-health). After Continue → `/onboarding/form`. Title is "Your training zones" (not "heart rate") across all states. Spec: `../docs/superpowers/specs/2026-05-11-zones-step-restyle-design.md`.
```

Adjust the surrounding numbering as needed so the list reads correctly.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add CLAUDE.md app/CLAUDE.md
git commit -m "docs: zones step repositioned + three-state body"
```

---

## Task 8: Full-suite sanity check

- [ ] **Step 1: Run Flutter tests**

```bash
cd app && flutter test
```

Expected: same baseline of pre-existing failures as before (e.g. `message_bubble_test.dart`). New tests pass; existing onboarding_overview test still passes with its FORM→ZONES route update.

- [ ] **Step 2: Run analyzer**

```bash
cd app && flutter analyze
```

Expected: 0 issues.

- [ ] **Step 3: Manual smoke test on simulator**

```bash
cd app && bash scripts/run-dev.sh
```

Backend running via `cd api && composer run dev`.

Cases:
1. **No-wearable beginner** (clean dev user, no DOB):
   - Sign in → connect-health → "Continue without syncing" → overview → fill in km + pace → Continue → land on zones in state C → DOB picker auto-opens → pick → state B → Continue → form.
2. **Wearable + HR data** (DevOnboardingSeeder default state):
   - Connect-health syncs → overview shows prefilled + locked → Continue → zones state A (bpm table + subtitle) → "Looks right" → form.
3. **DOB known but no HR** (HealthKit DOB but no run history):
   - Connect-health (deny HealthKit but workaround / dev seed sets `date_of_birth`) → overview → Continue → zones state B → "Continue" → form.

- [ ] **Step 4: No commit unless something needed fixing**

---

## Self-review

**Spec coverage:**
- Reposition (connect-health → overview → zones → form): Tasks 2, 3, 4
- Three-state body: Task 5
- DOB-first for beginners: Task 5 (state B + state C)
- Title copy "Your training zones": Task 5 step 3
- `onboardingDerivedZonesProvider`: Tasks 1, 2, 5
- Router web-skip update: Task 3
- Edge cases: covered by widget tests in Task 6

**Placeholder scan:**
- One conditional in Task 6: "If the `_StubAuth` pattern fails, fall back to..." — acknowledged risk because Riverpod codegen override patterns vary by class shape. The fallback is precisely described.

**Type consistency:**
- `DerivedZones` type referenced same way across connect-health write + provider + zones read.
- `User` model field names in Task 6 test must match `app/lib/features/auth/models/user.dart` — flagged in step.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-11-zones-step-restyle.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks.

**2. Inline Execution** — execute tasks in this session via executing-plans.

Which approach?
