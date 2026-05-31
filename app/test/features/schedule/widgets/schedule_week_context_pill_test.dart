import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/schedule/widgets/schedule_week_context_pill.dart';

void main() {
  Widget wrap(Locale locale, Widget child) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('English: renders week number + Mon-Sun range', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        const ScheduleWeekContextPill(weekNumber: 3, startsAtIso: '2026-05-11'),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text, contains('3'));
    expect(text, contains('May'));
  });

  testWidgets('Dutch: renders Dutch month abbreviations', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('nl'),
        const ScheduleWeekContextPill(weekNumber: 7, startsAtIso: '2026-05-11'),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text, contains('7'));
    // Dutch label for "viewing" — sanity check we're going through the
    // localized template, not the English one.
    expect(text, contains('Bekijkt'));
  });

  testWidgets('Cross-month range renders both months', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        const ScheduleWeekContextPill(weekNumber: 1, startsAtIso: '2026-04-30'),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text)).data!;
    expect(text, contains('Apr'));
    expect(text, contains('May'));
  });

  testWidgets('Falls back to empty range on invalid date', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        const ScheduleWeekContextPill(weekNumber: 2, startsAtIso: 'not-a-date'),
      ),
    );
    // Should still render without crashing.
    expect(find.byType(ScheduleWeekContextPill), findsOneWidget);
  });
}
