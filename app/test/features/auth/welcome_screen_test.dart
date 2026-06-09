import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/features/auth/screens/welcome_screen.dart';
import 'package:app/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    // Keep the test hermetic — no network font fetches (which would leave
    // pending timers and flake the pump). google_fonts falls back gracefully.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget harness() => const CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: WelcomeScreen(),
      );

  testWidgets('renders the RunBoost welcome hero without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    // Let the intro fade/slide settle without relying on pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 500));

    // Logo lockup is the outlined brand SVG (no 'RUNBOOST' text node).
    expect(find.byType(RunBoostWordmark), findsOneWidget);

    // Eyebrow + Anton slogan (3 stacked uppercase lines) + CTA copy.
    expect(find.text('YOUR AI RUNCOACH'), findsOneWidget);
    expect(find.text('TRAIN'), findsOneWidget);
    expect(find.text('SMARTER,'), findsOneWidget); // the gold hit-block word
    expect(find.text('NOT HARDER'), findsOneWidget);
    expect(find.text('SIGN IN WITH APPLE'), findsOneWidget);

    // No overflow / build exceptions surfaced during the pump.
    expect(tester.takeException(), isNull);
  });
}
