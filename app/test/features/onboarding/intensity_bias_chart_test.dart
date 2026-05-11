import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_chart.dart';

void main() {
  testWidgets('chart builds and survives a bias change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntensityBiasChart(bias: IntensityBias.standard),
        ),
      ),
    );
    expect(find.byType(IntensityBiasChart), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IntensityBiasChart(bias: IntensityBias.pushMeHarder),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(IntensityBiasChart), findsOneWidget);
  });
}
