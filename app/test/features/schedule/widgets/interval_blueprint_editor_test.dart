import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/schedule/models/interval_blueprint.dart';
import 'package:app/features/schedule/widgets/interval_blueprint_editor.dart';
import 'package:app/l10n/app_localizations.dart';

const _block800 = IntervalStep(
  type: 'block',
  reps: 4,
  workDistanceM: 800,
  workPaceSecondsPerKm: 270,
  recoverySeconds: 90,
);

const _bp = IntervalBlueprint(
  warmupSeconds: 60,
  steps: [_block800],
  cooldownSeconds: 300,
);

Widget _host(IntervalBlueprint bp, ValueChanged<IntervalBlueprint> onChanged) {
  return CupertinoApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SingleChildScrollView(
      child: IntervalBlueprintEditor(blueprint: bp, onChanged: onChanged),
    ),
  );
}

void main() {
  testWidgets('renders block rows, warmup, cooldown and derived distance',
      (tester) async {
    await tester.pumpWidget(_host(_bp, (_) {}));

    expect(find.text('Block 1'), findsOneWidget);
    expect(find.text('4×'), findsOneWidget);
    expect(find.text('800m'), findsOneWidget);
    expect(find.text('90s'), findsOneWidget); // recovery
    expect(find.text('60s'), findsOneWidget); // warmup
    expect(find.text('300s'), findsOneWidget); // cooldown
    // Live derived distance — same value as the PHP estimator (5.1 km).
    expect(find.textContaining('5.1 km'), findsOneWidget);
  });

  testWidgets('add block appends a copy of the last block', (tester) async {
    IntervalBlueprint? changed;
    await tester.pumpWidget(_host(_bp, (bp) => changed = bp));

    await tester.tap(find.textContaining('Add block'));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.steps, hasLength(2));
    expect(changed!.steps[1].type, 'block');
    expect(changed!.steps[1].workDistanceM, 800);
  });

  testWidgets('delete is hidden for a single block, removes one of two',
      (tester) async {
    await tester.pumpWidget(_host(_bp, (_) {}));
    expect(find.byKey(const ValueKey('delete-block-0')), findsNothing);

    IntervalBlueprint? changed;
    final two = _bp.copyWith(steps: [_block800, _block800]);
    await tester.pumpWidget(_host(two, (bp) => changed = bp));

    await tester.tap(find.byKey(const ValueKey('delete-block-1')));
    await tester.pump();

    expect(changed!.steps, hasLength(1));
  });

  testWidgets('standalone rep and rest steps render as fixed rows',
      (tester) async {
    final pyramid = _bp.copyWith(steps: [
      _block800,
      const IntervalStep(type: 'rep', workDistanceM: 1000, workPaceSecondsPerKm: 280),
      const IntervalStep(type: 'rest', durationSeconds: 120),
    ]);
    await tester.pumpWidget(_host(pyramid, (_) {}));

    expect(find.textContaining('1× 1000m'), findsOneWidget);
    expect(find.textContaining('Rest'), findsOneWidget);
    // Fixed rows expose no delete control.
    expect(find.byKey(const ValueKey('delete-block-1')), findsNothing);
    expect(find.byKey(const ValueKey('delete-block-2')), findsNothing);
  });
}
