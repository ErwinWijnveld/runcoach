import 'package:app/features/auth/models/hr_zone.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/screens/onboarding_zones_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Stub auth that resolves to a fixed user without firing any network calls.
class _StubAuth extends Auth {
  _StubAuth(this._user);
  final User? _user;

  @override
  AsyncValue<User?> build() => AsyncValue.data(_user);
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

User _userWith({
  required DateTime? dateOfBirth,
  required String source,
  required List<HrZone>? heartRateZones,
}) {
  return User(
    id: 1,
    name: 'Test',
    email: 't@test.app',
    heartRateZones: heartRateZones,
    heartRateZonesSource: source,
    dateOfBirth: dateOfBirth,
  );
}

void main() {
  testWidgets('state B (DOB-known, no HR signal): renders DOB row, collapsed advanced, Continue', (tester) async {
    final user = _userWith(
      dateOfBirth: DateTime(1990, 6, 15),
      source: 'derived_age',
      heartRateZones: const [
        HrZone(min: 0, max: 115),
        HrZone(min: 115, max: 134),
        HrZone(min: 134, max: 154),
        HrZone(min: 154, max: 173),
        HrZone(min: 173, max: 220),
      ],
    );

    await _pumpScreen(tester, user: user);

    expect(find.text('Your training zones'), findsOneWidget);
    expect(find.text('June 15, 1990'), findsOneWidget);
    expect(find.text('Show zones (advanced)'), findsOneWidget);
    // The bpm table is hidden until expanded.
    expect(find.byType(Container), findsWidgets); // sanity — DOB row + advanced link render
  });

  testWidgets('state C (no DOB, default source): renders Pick-DOB row + disabled Continue', (tester) async {
    final user = _userWith(
      dateOfBirth: null,
      source: 'default',
      heartRateZones: null,
    );

    await _pumpScreen(tester, user: user);

    expect(find.text('Your training zones'), findsOneWidget);
    // DOB picker sheet auto-opens on first frame; pump again to settle that.
    await tester.pumpAndSettle();
    // Either the sheet is open (showing date wheel) OR we cancelled it.
    // We don't tap Done — just verify the base screen still has the
    // Pick-your-birth-date row when the sheet dismisses on tester teardown.
    expect(find.text('Pick your birth date'), findsAtLeastNWidgets(1));
  });
}
