import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_segmented_control.dart';
import 'package:app/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'segmented control renders three labels and reports taps',
    (tester) async {
      IntensityBias? captured;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Material(
              child: IntensityBiasSegmentedControl(
                selected: IntensityBias.standard,
                onChanged: (b) => captured = b,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Easier'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Harder'), findsOneWidget);
      expect(find.text('(auto-pick)'), findsOneWidget);

      await tester.tap(find.text('Harder'));
      await tester.pump();
      expect(captured, IntensityBias.pushMeHarder);
    },
  );

  testWidgets(
    'auto-pick label has opacity 0 when non-standard selected',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Material(
              child: IntensityBiasSegmentedControl(
                selected: IntensityBias.pushMeHarder,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    },
  );
}
