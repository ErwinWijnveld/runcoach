import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
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
      backgroundColor: AppColors.neutral,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            colors: [
              AppColors.neutral,
              Color(0xFFFAF1D9),
              AppColors.neutral,
              Color(0xFFFAF1D9),
              AppColors.neutral,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/coach');
                  }
                },
              ),
              Expanded(
                child: messagesAsync.when(
                  loading: () => const AppSpinner(),
                  error: (err, _) => AppErrorState(title: 'Error: $err'),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _EmptyState(onQuickAction: _send);
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Column(
                          crossAxisAlignment: msg.role == 'user'
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
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
                              onChipTap: (label, value) => ref
                                  .read(coachChatProvider(widget.conversationId)
                                      .notifier)
                                  .sendMessage(label, chipValue: value),
                            ),
                            if (msg.proposal != null) ...[
                              const SizedBox(height: 10),
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
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: CoachPromptBar.input(
                  controller: _controller,
                  onSubmit: (_) => _send(),
                  sending: _sending,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            onPressed: onBack,
            child: const Icon(
              CupertinoIcons.chevron_left,
              size: 22,
              color: AppColors.primaryInk,
            ),
          ),
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
