import 'package:app/features/onboarding/widgets/locked_stat_field.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping lock shows confirmation; Edit anyway calls onUnlock', (tester) async {
    var unlockedCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: 'Apple Health',
            locked: true,
            onUnlock: () => unlockedCount++,
            onTapWhenUnlocked: () {},
          ),
        ),
      ),
    );

    expect(find.text('24 km'), findsOneWidget);
    expect(find.text('From Apple Health'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.lock_fill));
    await tester.pumpAndSettle();

    expect(find.text('Edit anyway'), findsOneWidget);
    await tester.tap(find.text('Edit anyway'));
    await tester.pumpAndSettle();

    expect(unlockedCount, 1);
  });

  testWidgets('tapping lock shows confirmation; Cancel keeps locked', (tester) async {
    var unlockedCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: 'Apple Health',
            locked: true,
            onUnlock: () => unlockedCount++,
            onTapWhenUnlocked: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.lock_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(unlockedCount, 0);
  });

  testWidgets('unlocked field calls onTapWhenUnlocked on tap', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CupertinoPageScaffold(
          child: LockedStatField(
            label: 'Weekly km',
            valueText: '24 km',
            sourceLabel: null,
            locked: false,
            onUnlock: () {},
            onTapWhenUnlocked: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('24 km'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });
}
