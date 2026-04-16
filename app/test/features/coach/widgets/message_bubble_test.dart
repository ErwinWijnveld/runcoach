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
  testWidgets('renders streaming caret when streaming with content',
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

  testWidgets(
    'renders thinking card with default label while streaming with empty content',
    (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: MessageBubble(message: _msg(content: '', streaming: true)),
        ),
      );

      expect(find.text('Working on your plan'), findsOneWidget);
    },
  );

  testWidgets('uses humanized tool indicator as thinking label',
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

    // trailing ellipsis stripped for the card
    expect(find.text('Looking up your activities'), findsOneWidget);
  });

  testWidgets('does not render thinking card when not streaming',
      (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MessageBubble(
          message: _msg(content: 'Done', streaming: false),
        ),
      ),
    );

    expect(find.text('Working on your plan'), findsNothing);
  });
}
