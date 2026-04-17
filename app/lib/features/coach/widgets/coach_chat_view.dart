import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';
import 'package:app/features/coach/widgets/plan_details_sheet.dart';
import 'package:app/features/coach/widgets/proposal_card.dart';
import 'package:app/features/coach/widgets/quick_action_card.dart';

class CoachChatView extends ConsumerStatefulWidget {
  final String conversationId;
  final AsyncValue<List<CoachMessage>> Function(WidgetRef) watchMessages;
  final Future<void> Function(WidgetRef, String text, {String? chipValue}) sendMessage;
  final Future<void> Function(WidgetRef, String messageId)? onRetry;
  final void Function(WidgetRef)? onInvalidate;
  final Future<void> Function(WidgetRef, int proposalId)? onAccept;
  final Future<void> Function(WidgetRef, int proposalId)? onReject;

  const CoachChatView({
    super.key,
    required this.conversationId,
    required this.watchMessages,
    required this.sendMessage,
    this.onRetry,
    this.onInvalidate,
    this.onAccept,
    this.onReject,
  });

  @override
  ConsumerState<CoachChatView> createState() => _CoachChatViewState();
}

class _CoachChatViewState extends ConsumerState<CoachChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  Future<void> _send([String? prefill, String? chipValue]) async {
    final content = prefill ?? _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    setState(() => _sending = true);

    // sendMessage() appends the optimistic user + streaming messages to state
    // synchronously before awaiting. Schedule a post-frame scroll so the user
    // sees their just-sent message even if they had scrolled up earlier.
    final future = widget.sendMessage(ref, content, chipValue: chipValue);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());

    try {
      await future;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // In a reversed ListView, pixels=0 is the visual bottom (newest message).
  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = widget.watchMessages(ref);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const AppSpinner(),
            error: (err, _) => AppErrorState(title: 'Error: $err'),
            data: (messages) {
              if (messages.isEmpty) {
                return _EmptyState(onQuickAction: (text) => _send(text));
              }
              // Reversed ListView: index 0 is the newest message, rendered at
              // the visual bottom. Streaming text growing in the bottom bubble
              // stays anchored to the bottom automatically; when the keyboard
              // opens and the viewport shrinks, the newest messages remain
              // visible above the input without any manual scroll management.
              return ListView.separated(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  return Column(
                    crossAxisAlignment: msg.role == 'user'
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      MessageBubble(
                        message: msg,
                        onRetry: (msg.errorDetail != null && widget.onRetry != null)
                            ? () => widget.onRetry!(ref, msg.id)
                            : null,
                        onChipTap: (label, value) => _send(label, value),
                      ),
                      if (msg.proposal != null && widget.onAccept != null) ...[
                        const SizedBox(height: 10),
                        ProposalCard(
                          proposal: msg.proposal!,
                          onAccept: () async {
                            await widget.onAccept!(ref, msg.proposal!.id);
                            widget.onInvalidate?.call(ref);
                          },
                          onAdjust: () async {
                            await widget.onReject?.call(ref, msg.proposal!.id);
                            widget.onInvalidate?.call(ref);
                          },
                          onViewDetails: () => PlanDetailsSheet.show(
                            context,
                            proposal: msg.proposal!,
                            onAccept: () async {
                              await widget.onAccept!(ref, msg.proposal!.id);
                              widget.onInvalidate?.call(ref);
                            },
                            onAdjust: () async {
                              await widget.onReject?.call(ref, msg.proposal!.id);
                              widget.onInvalidate?.call(ref);
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: CoachPromptBar.input(
              controller: _controller,
              onSubmit: (_) => _send(),
              sending: _sending,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onQuickAction;
  const _EmptyState({required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.sparkles,
            size: 48,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'What can I help you with?',
            style: RunCoreText.serifTitle(size: 28, height: 32 / 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'I know your training history and can manage your schedule',
            style: RunCoreText.statSuffix(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              QuickActionCard(
                emoji: '\u{1F4C5}',
                title: 'Create a training plan',
                subtitle: 'For an upcoming race',
                onTap: () => onQuickAction(
                  'I want to create a training plan for an upcoming race',
                ),
              ),
              QuickActionCard(
                emoji: '\u{1F504}',
                title: 'Adjust my schedule',
                subtitle: "Modify this week's plan",
                onTap: () =>
                    onQuickAction("Can you adjust this week's training schedule?"),
              ),
              QuickActionCard(
                emoji: '\u{1F4CA}',
                title: 'Analyze my progress',
                subtitle: 'How am I trending?',
                onTap: () => onQuickAction(
                  'How is my training going? Give me an analysis of my progress.',
                ),
              ),
              QuickActionCard(
                emoji: '\u{2753}',
                title: 'Ask anything',
                subtitle: 'Training advice & tips',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
