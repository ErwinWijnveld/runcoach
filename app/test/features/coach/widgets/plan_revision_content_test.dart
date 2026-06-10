import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/widgets/plan_revision_content.dart';
import 'package:app/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  setUpAll(() {
    // Keep google_fonts off the network in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const beforeText =
      'Intervals · 5.8 km · Z5 · 5×400m @4:12/km (rec 90s)';
  const afterText =
      'Intervals · 5.5 km · Z5 · 5×600m @4:15/km (rec 120s)';

  Map<String, dynamic> adjustOp() => {
        'action': 'adjust',
        'week': 2,
        'day_of_week': 2,
        'before': {
          'type': 'interval',
          'target_km': 5.8,
          'target_heart_rate_zone': 5,
          'intervals': '5×400m @4:12/km (rec 90s)',
        },
        'type': 'interval',
        'target_km': 5.5,
        'target_heart_rate_zone': 5,
        'intervals': '5×600m @4:15/km (rec 120s)',
        'adjustments': ['Rep count set to 60 (you asked for 100; allowed range is 1–60).'],
      };

  testWidgets('edit renders before and after as separate tinted lines',
      (tester) async {
    await tester.pumpWidget(_wrap(PlanRevisionContent(ops: [adjustOp()])));

    // Two distinct lines instead of one merged "A → B" blob.
    expect(find.text(beforeText), findsOneWidget);
    expect(find.text(afterText), findsOneWidget);
    expect(find.textContaining('→'), findsNothing);

    // Labelled chips make the direction unmistakable.
    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);

    // Red-tinted old state, green new state.
    expect(
      tester.widget<Text>(find.text(beforeText)).style?.color,
      AppColors.danger,
    );
    expect(
      tester.widget<Text>(find.text(afterText)).style?.color,
      AppColors.successInk,
    );

    // The server-adjustment note still renders.
    expect(find.textContaining('Rep count set to 60'), findsOneWidget);
  });

  testWidgets('remove shows the dropped session as a red BEFORE line',
      (tester) async {
    await tester.pumpWidget(_wrap(const PlanRevisionContent(ops: [
      {
        'action': 'remove',
        'week': 3,
        'day_of_week': 5,
        'before': {'type': 'easy', 'target_km': 5.0},
      },
    ])));

    expect(find.text('BEFORE'), findsOneWidget);
    final line = find.text('Easy · 5 km');
    expect(line, findsOneWidget);
    expect(tester.widget<Text>(line).style?.color, AppColors.danger);
  });

  testWidgets('add shows the new session as a green AFTER line',
      (tester) async {
    await tester.pumpWidget(_wrap(const PlanRevisionContent(ops: [
      {
        'action': 'add',
        'week': 4,
        'day_of_week': 3,
        'type': 'easy',
        'target_km': 6.0,
      },
    ])));

    expect(find.text('AFTER'), findsOneWidget);
    expect(find.text('BEFORE'), findsNothing);
    final line = find.text('Easy · 6 km');
    expect(line, findsOneWidget);
    expect(tester.widget<Text>(line).style?.color, AppColors.successInk);
  });

  testWidgets('identical before/after collapses to a single green line',
      (tester) async {
    await tester.pumpWidget(_wrap(const PlanRevisionContent(ops: [
      {
        'action': 'adjust',
        'week': 1,
        'day_of_week': 2,
        'before': {'type': 'easy', 'target_km': 5.0},
        'type': 'easy',
        'target_km': 5.0,
      },
    ])));

    // A description-only edit summarizes the same on both sides — showing
    // an identical red line would read as a change that didn't happen.
    expect(find.text('BEFORE'), findsNothing);
    expect(find.text('AFTER'), findsOneWidget);
    expect(find.text('Easy · 5 km'), findsOneWidget);
  });

  testWidgets('chips localize to VOOR/NA in Dutch', (tester) async {
    await tester.pumpWidget(_wrap(
      PlanRevisionContent(ops: [adjustOp()]),
      locale: const Locale('nl'),
    ));

    expect(find.text('VOOR'), findsOneWidget);
    expect(find.text('NA'), findsOneWidget);
  });
}
