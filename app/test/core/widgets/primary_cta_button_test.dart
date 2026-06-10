import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/primary_cta_button.dart';

Widget _host(Widget child) => CupertinoApp(home: Center(child: child));

void main() {
  testWidgets('renders gold pill with uppercase label', (tester) async {
    await tester.pumpWidget(_host(
      PrimaryCtaButton(label: 'Opslaan', onPressed: () {}),
    ));

    expect(find.text('OPSLAAN'), findsOneWidget);
    final button = tester.widget<CupertinoButton>(find.byType(CupertinoButton));
    expect(button.color, AppColors.secondary);
  });

  testWidgets('busy shows spinner instead of label', (tester) async {
    await tester.pumpWidget(_host(
      const PrimaryCtaButton(label: 'Opslaan', onPressed: null, busy: true),
    ));

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.text('OPSLAAN'), findsNothing);
  });

  testWidgets('disabled (null onPressed, not busy) renders dimmed',
      (tester) async {
    await tester.pumpWidget(_host(
      const PrimaryCtaButton(label: 'Opslaan', onPressed: null),
    ));

    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, 0.5);
  });
}
