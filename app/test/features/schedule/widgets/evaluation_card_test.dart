import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/schedule/models/plan_evaluation.dart';
import 'package:app/features/schedule/widgets/evaluation_card.dart';

void main() {
  Widget wrap(Locale locale, Widget child) {
    return CupertinoApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: CupertinoPageScaffold(child: Center(child: child)),
    );
  }

  PlanEvaluation evaluation({
    required String status,
    String scheduledFor = '2026-06-15',
  }) {
    return PlanEvaluation(
      id: 1,
      userId: 1,
      goalId: 1,
      scheduledFor: scheduledFor,
      status: status,
    );
  }

  testWidgets('title is the week check-in, not the status word', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: EvaluationCard(
            evaluation: evaluation(status: 'ready'),
            weekNumber: 2,
          ),
        ),
      ),
    );

    expect(find.text('CHECK-IN'), findsOneWidget);
    expect(find.text('Week 2 check-in'), findsOneWidget);
    // The status word is no longer rendered as the visible title.
    expect(find.text('Report ready'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('pending shows week title and hides Open button',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: EvaluationCard(
            evaluation: evaluation(status: 'pending'),
            weekNumber: 4,
          ),
        ),
      ),
    );

    expect(find.text('Week 4 check-in'), findsOneWidget);
    expect(find.text('Up next'), findsNothing);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('falls back to the generic title when weekNumber is unknown',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: EvaluationCard(evaluation: evaluation(status: 'ready')),
        ),
      ),
    );

    expect(find.text('2-week check-in'), findsOneWidget);
    expect(find.textContaining('Week '), findsNothing);
  });

  testWidgets('renders Dutch copy when locale=nl', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('nl'),
        SizedBox(
          width: 360,
          child: EvaluationCard(
            evaluation: evaluation(status: 'ready'),
            weekNumber: 2,
          ),
        ),
      ),
    );

    expect(find.text('EVALUATIE'), findsOneWidget);
    expect(find.text('Week 2 check-in'), findsOneWidget);
    expect(find.text('Openen'), findsOneWidget);
  });

  testWidgets('accepted is tappable so the runner can re-read the report',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: EvaluationCard(
            evaluation: evaluation(status: 'accepted'),
            weekNumber: 2,
          ),
        ),
      ),
    );

    expect(find.text('Week 2 check-in'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('status is preserved in the accessibility label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: EvaluationCard(
            evaluation: evaluation(status: 'ready'),
            weekNumber: 2,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('Report ready')), findsOneWidget);
    handle.dispose();
  });
}
