import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/widgets/runboost_logo.dart';

void main() {
  testWidgets('renders its copy uppercased (brand contract)', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(home: RunBoostHeading('Week 2 check-in')),
    );

    // findHeading() in test/helpers/finders.dart relies on this transform
    // living HERE and nowhere else — copy stays l10n-cased, rendering is
    // uppercase Anton per the RunBoost brand guidelines.
    expect(find.text('WEEK 2 CHECK-IN'), findsOneWidget);
    expect(find.text('Week 2 check-in'), findsNothing);
  });
}
