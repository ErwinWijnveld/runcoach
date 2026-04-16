import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';

CoachMessage _msg({
  required String content,
  bool streaming = false,
  String? toolIndicator,
}) =>
    CoachMessage(
      id: 'm',
      role: 'assistant',
      content: content,
      createdAt: '2026-04-15T00:00:00Z',
      streaming: streaming,
      toolIndicator: toolIndicator,
    );

void main() {
  testWidgets('renders streaming caret when streaming is true',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(message: _msg(content: 'Hello', streaming: true)),
      ),
    );

    expect(find.byKey(const Key('streaming-caret')), findsOneWidget);
  });

  testWidgets('does not render caret when streaming is false', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(message: _msg(content: 'Hello', streaming: false)),
      ),
    );

    expect(find.byKey(const Key('streaming-caret')), findsNothing);
  });

  testWidgets('renders tool indicator pill when toolIndicator is set',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(
          message: _msg(
            content: '',
            streaming: true,
            toolIndicator: 'Looking up your activities…',
          ),
        ),
      ),
    );

    expect(find.text('Looking up your activities…'), findsOneWidget);
  });

  testWidgets('does not render pill when toolIndicator is null',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(
          message: _msg(content: 'Done', streaming: false),
        ),
      ),
    );

    expect(find.byKey(const Key('tool-indicator-pill')), findsNothing);
  });
}
