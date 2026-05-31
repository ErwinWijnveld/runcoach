import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/share/widgets/run_share_card.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

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

  final route = [
    for (var i = 0; i < 25; i++)
      WorkoutRoutePoint(
        lat: 52.36 + i * 0.0005,
        lng: 4.90 + i * 0.0007,
        timestampMs: i * 1000,
      ),
  ];

  testWidgets('renders with route, EN locale', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: RunShareCard(
            route: route,
            activityDate: DateTime(2026, 5, 18),
            distanceKm: 10.2,
            durationSeconds: 3138,
            averagePaceSecondsPerKm: 308,
            averageHeartRate: 162,
            complianceScore: 9.4,
            aiFeedback:
                '**Strong negative split.** You opened easy and dropped pace in the last 3km.',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('AVG BPM'), findsOneWidget);
    expect(find.text('ON-PLAN'), findsOneWidget);
    expect(find.byType(RunShareCard), findsOneWidget);
  });

  testWidgets('renders no-route fallback with INDOOR pill', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: RunShareCard(
            route: const [],
            activityDate: DateTime(2026, 5, 18),
            distanceKm: 6.5,
            durationSeconds: 2100,
            averagePaceSecondsPerKm: 323,
            averageHeartRate: 158,
            complianceScore: 8.8,
            aiFeedback: 'Solid easy effort throughout.',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('INDOOR RUN'), findsOneWidget);
  });

  testWidgets('hides HR + compliance tiles when missing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('en'),
        SizedBox(
          width: 360,
          child: RunShareCard(
            route: route,
            activityDate: DateTime(2026, 5, 18),
            distanceKm: 5.0,
            durationSeconds: 1800,
            averagePaceSecondsPerKm: 360,
            aiFeedback: '**Easy aerobic run.** Smooth.',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('AVG BPM'), findsNothing);
    expect(find.text('ON-PLAN'), findsNothing);
  });

  testWidgets('renders Dutch labels on NL locale', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Locale('nl'),
        SizedBox(
          width: 360,
          child: RunShareCard(
            route: route,
            activityDate: DateTime(2026, 5, 18),
            distanceKm: 10.2,
            durationSeconds: 3138,
            averagePaceSecondsPerKm: 308,
            averageHeartRate: 162,
            complianceScore: 9.4,
            aiFeedback: '**Sterk negatief splittijd.**',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.text('AFSTAND'), findsOneWidget);
    expect(find.text('TIJD'), findsOneWidget);
    expect(find.text('GEM. TEMPO'), findsOneWidget);
    expect(find.text('OP SCHEMA'), findsOneWidget);
  });
}
