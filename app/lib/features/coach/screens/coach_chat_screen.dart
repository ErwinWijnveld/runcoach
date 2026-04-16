import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';
import 'package:app/features/coach/widgets/proposal_card.dart';
import 'package:app/features/coach/widgets/quick_action_card.dart';

class CoachChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const CoachChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  Future<void> _send([String? prefill]) async {
    final content = prefill ?? _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    setState(() => _sending = true);

    final notifier = ref.read(
      coachChatProvider(widget.conversationId).notifier,
    );
    await notifier.sendMessage(content);

    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) < 80;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachChatProvider(widget.conversationId));

    ref.listen<AsyncValue<List<CoachMessage>>>(
      coachChatProvider(widget.conversationId),
      (previous, next) {
        if (next.value == null) return;
        if (!_isNearBottom()) return;
        _scrollToBottom();
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        middle: const Text('Coach'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const AppSpinner(),
                error: (err, _) => AppErrorState(title: 'Error: $err'),
                data: (messages) {
                  if (messages.isEmpty) {
                    return _EmptyState(onQuickAction: _send);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Column(
                        children: [
                          MessageBubble(
                            message: msg,
                            onRetry: msg.errorDetail != null
                                ? () => ref
                                    .read(coachChatProvider(
                                            widget.conversationId)
                                        .notifier)
                                    .retry(msg.id)
                                : null,
                          ),
                          if (msg.proposal != null)
                            ProposalCard(
                              proposal: msg.proposal!,
                              onAccept: () async {
                                final notifier = ref.read(
                                  coachChatProvider(widget.conversationId)
                                      .notifier,
                                );
                                await notifier
                                    .acceptProposal(msg.proposal!.id);
                                ref.invalidate(
                                  coachChatProvider(widget.conversationId),
                                );
                              },
                              onReject: () async {
                                final notifier = ref.read(
                                  coachChatProvider(widget.conversationId)
                                      .notifier,
                                );
                                await notifier
                                    .rejectProposal(msg.proposal!.id);
                                ref.invalidate(
                                  coachChatProvider(widget.conversationId),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _ChatInput(
              controller: _controller,
              sending: _sending,
              onSend: () => _send(),
            ),
          ],
        ),
      ),
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
            color: AppColors.warmBrown,
          ),
          const SizedBox(height: 16),
          const Text(
            'What can I help you with?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'I know your training history and can manage your schedule',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
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

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: Color(0x14000000), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Ask your coach...',
              placeholderStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            onPressed: sending ? null : onSend,
            child: sending
                ? const CupertinoActivityIndicator()
                : const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: AppColors.warmBrown,
                    size: 32,
                  ),
          ),
        ],
      ),
    );
  }
}
