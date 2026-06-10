import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/widgets/plan_details_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/finders.dart';

void main() {
  group('PlanDetailsSheet feasibility', () {
    testWidgets('renders zone-bar when ambition payload present',
        (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 78,
        'pace_score_pct': 83,
        'volume_score_pct': 88,
        'verdict_zone': 'ok',
        'verdict_label': 'Pittig maar haalbaar',
        'detail': '10 sec/km per maand verbetering nodig.',
        'adjust_prefill': null,
      });

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {},
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(findHeading('Pittig maar haalbaar'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Unrealistic'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('skips section when ambition is null', (tester) async {
      final proposal = _makeProposal(ambition: null);

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {},
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Unrealistic'), findsNothing);
      expect(findHeading('Pittig maar haalbaar'), findsNothing);
    });

    testWidgets('red CTA fires onAdjust with prefill when zone unrealistic',
        (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 28,
        'pace_score_pct': 32,
        'volume_score_pct': 60,
        'verdict_zone': 'unrealistic',
        'verdict_label': 'Te ambitieus',
        'detail': '38 sec/km per maand vraagt 3× realistische rate.',
        'adjust_prefill': 'Mijn doel voelt te ambitieus.',
      });

      String? capturedPrefill;
      var adjustCalls = 0;

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {
          adjustCalls++;
          capturedPrefill = prefill;
        },
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('ADJUST GOAL FOR REALISTIC PLAN'), findsOneWidget);

      await tester.tap(find.text('ADJUST GOAL FOR REALISTIC PLAN'));
      await tester.pumpAndSettle();

      expect(adjustCalls, 1);
      expect(capturedPrefill, 'Mijn doel voelt te ambitieus.');
    });

    testWidgets('soft ADJUST passes null prefill when zone ok',
        (tester) async {
      final proposal = _makeProposal(ambition: {
        'feasibility_pct': 78,
        'verdict_zone': 'ok',
        'verdict_label': 'Goed',
        'detail': 'ok',
        'adjust_prefill': 'should-not-leak',
      });

      String? capturedPrefill = 'sentinel';

      await tester.pumpWidget(_host(
        proposal: proposal,
        onAdjust: ({String? prefill}) async {
          capturedPrefill = prefill;
        },
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ADJUST'));
      await tester.pumpAndSettle();

      expect(capturedPrefill, isNull);
    });
  });
}

CoachProposal _makeProposal({Map<String, dynamic>? ambition}) {
  return CoachProposal(
    id: 1,
    type: 'create_schedule',
    status: 'pending',
    payload: {
      'goal_name': 'Test 5K',
      'schedule': {
        'weeks': [
          {
            'week_number': 1,
            'total_km': 20.0,
            'days': [
              {'day_of_week': 1, 'type': 'easy', 'target_km': 5.0},
            ],
          },
          {
            'week_number': 2,
            'total_km': 22.0,
            'days': [
              {'day_of_week': 1, 'type': 'easy', 'target_km': 5.5},
            ],
          },
        ],
      },
      'ambition': ?ambition,
    },
  );
}

Widget _host({
  required CoachProposal proposal,
  required Future<void> Function({String? prefill}) onAdjust,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => PlanDetailsSheet.show(
              context,
              proposal: proposal,
              onAccept: () async {},
              onAdjust: onAdjust,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}
