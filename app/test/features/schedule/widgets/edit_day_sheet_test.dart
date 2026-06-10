import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/widgets/edit_day_sheet.dart';
import 'package:app/l10n/app_localizations.dart';

TrainingDay _day({required String type, Map<String, dynamic>? intervals}) =>
    TrainingDay.fromJson({
      'id': 1,
      'date': '2026-06-12',
      'type': type,
      'title': type == 'interval' ? 'Intervals' : 'Easy',
      'target_km': type == 'interval' ? 5.1 : 8.0,
      'target_pace_seconds_per_km': type == 'interval' ? null : 360,
      'intervals_json': intervals,
      'order': 5,
    });

Widget _host(TrainingDay day) => ProviderScope(
      child: CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditDaySheet(day: day),
      ),
    );

void main() {
  testWidgets('interval day renders the block editor without layout errors',
      (tester) async {
    // Guards the Flexible-inside-min-Column layout in the real sheet shell —
    // a RenderFlex misuse only surfaces at runtime, not in analyze.
    await tester.pumpWidget(_host(_day(type: 'interval', intervals: {
      'warmup_seconds': 60,
      'steps': [
        {
          'type': 'block',
          'reps': 4,
          'work_distance_m': 800,
          'work_pace_seconds_per_km': 270,
          'recovery_seconds': 90,
        },
      ],
      'cooldown_seconds': 300,
    })));

    expect(tester.takeException(), isNull);
    expect(find.text('Block 1'), findsOneWidget);
    expect(find.textContaining('5.1 km'), findsOneWidget);
    // Day-level distance/pace rows are NOT shown for interval days.
    expect(find.text('Distance'), findsNothing);
  });

  testWidgets('interval day without blueprint seeds the default skeleton',
      (tester) async {
    await tester.pumpWidget(_host(_day(type: 'interval')));

    expect(tester.takeException(), isNull);
    expect(find.text('Block 1'), findsOneWidget);
    expect(find.text('400m'), findsOneWidget);
  });

  testWidgets('regular day keeps the distance and pace rows', (tester) async {
    await tester.pumpWidget(_host(_day(type: 'easy')));

    expect(tester.takeException(), isNull);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('Block 1'), findsNothing);
  });
}
