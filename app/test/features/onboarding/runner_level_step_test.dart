import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/onboarding/widgets/choice_group.dart';

void main() {
  testWidgets('runner-level mutator updates form state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Material(
            child: Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(onboardingFormProvider).runnerLevel;
                return ChoiceGroup<RunnerLevel>(
                  options: const [
                    ChoiceOption(value: RunnerLevel.beginner, label: 'Beginner'),
                    ChoiceOption(
                      value: RunnerLevel.intermediate,
                      label: 'Intermediate',
                    ),
                    ChoiceOption(value: RunnerLevel.advanced, label: 'Advanced'),
                    ChoiceOption(value: RunnerLevel.subElite, label: 'Sub-Elite'),
                    ChoiceOption(value: RunnerLevel.elite, label: 'Elite'),
                  ],
                  selected: selected,
                  onSelected:
                      ref.read(onboardingFormProvider.notifier).setRunnerLevel,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Sub-Elite'), findsOneWidget);
    expect(find.text('Elite'), findsOneWidget);

    expect(
      container.read(onboardingFormProvider).runnerLevel,
      RunnerLevel.intermediate,
    );

    await tester.tap(find.text('Beginner'));
    await tester.pump();
    expect(
      container.read(onboardingFormProvider).runnerLevel,
      RunnerLevel.beginner,
    );
  });
}
