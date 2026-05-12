import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';
import 'package:app/features/onboarding/providers/onboarding_profile_provider.dart';
import 'package:app/features/onboarding/screens/onboarding_overview_screen.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _SaveCapture {
  double? weeklyKm;
  int? easyPaceSecondsPerKm;
  int calls = 0;
}

class _StubProfileController extends OnboardingProfileController {
  _StubProfileController(this._profile);
  final OnboardingProfile _profile;

  @override
  Future<OnboardingProfile> build() async => _profile;
}

Future<_SaveCapture> _pumpScreen(
  WidgetTester tester, {
  required OnboardingProfile profile,
}) async {
  final capture = _SaveCapture();

  final router = GoRouter(
    initialLocation: '/onboarding/overview',
    routes: [
      GoRoute(
        path: '/onboarding/overview',
        builder: (_, _) => const OnboardingOverviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/form',
        builder: (_, _) => const Material(child: Center(child: Text('ZONES REACHED'))),
      ),
      GoRoute(
        path: '/onboarding/zones',
        builder: (_, _) => const Material(child: Center(child: Text('ZONES REACHED'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingProfileControllerProvider.overrideWith(
          () => _StubProfileController(profile),
        ),
        saveSelfReportedStatsCallProvider.overrideWith(
          (ref) => ({double? weeklyKm, int? easyPaceSecondsPerKm}) async {
            capture.calls++;
            capture.weeklyKm = weeklyKm;
            capture.easyPaceSecondsPerKm = easyPaceSecondsPerKm;
          },
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return capture;
}

void main() {
  testWidgets('no-wearable user: continue disabled until both fields touched', (tester) async {
    const profile = OnboardingProfile(
      status: 'ready',
      baseline: OnboardingBaseline(
        weeklyKm: null,
        weeklyKmSource: null,
        easyPaceSecondsPerKm: 360,
        easyPaceSource: null,
      ),
    );

    final capture = await _pumpScreen(tester, profile: profile);

    // Initial state: Continue disabled. Enter weekly km.
    await tester.enterText(find.byType(CupertinoTextField), '25');
    await tester.pumpAndSettle();

    // Pick pace via wheel.
    await tester.tap(find.text('Tap to choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Now Continue should work.
    expect(find.text('ZONES REACHED'), findsNothing);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('ZONES REACHED'), findsOneWidget);
    expect(capture.calls, 1);
    expect(capture.weeklyKm, 25.0);
    expect(capture.easyPaceSecondsPerKm, 360);
  });

  testWidgets('wearable user can continue without unlocking — sends nulls', (tester) async {
    const profile = OnboardingProfile(
      status: 'ready',
      baseline: OnboardingBaseline(
        weeklyKm: 24.0,
        weeklyKmSource: 'apple_health',
        easyPaceSecondsPerKm: 330,
        easyPaceSource: 'apple_health',
      ),
    );

    final capture = await _pumpScreen(tester, profile: profile);

    expect(find.text('24 km'), findsOneWidget);
    expect(find.text('5:30 /km'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.lock_fill), findsNWidgets(2));

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(capture.calls, 1);
    expect(capture.weeklyKm, isNull);
    expect(capture.easyPaceSecondsPerKm, isNull);
    expect(find.text('ZONES REACHED'), findsOneWidget);
  });
}
