import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
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

    final notifier = ref.read(coachChatProvider(widget.conversationId).notifier);
    await notifier.sendMessage(content);

    setState(() => _sending = false);
    _scrollToBottom();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
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
                        MessageBubble(message: msg),
                        if (msg.proposal != null)
                          ProposalCard(
                            proposal: msg.proposal!,
                            onAccept: () async {
                              final notifier = ref.read(
                                coachChatProvider(widget.conversationId).notifier,
                              );
                              await notifier.acceptProposal(msg.proposal!.id);
                              ref.invalidate(coachChatProvider(widget.conversationId));
                            },
                            onReject: () async {
                              final notifier = ref.read(
                                coachChatProvider(widget.conversationId).notifier,
                              );
                              await notifier.rejectProposal(msg.proposal!.id);
                              ref.invalidate(coachChatProvider(widget.conversationId));
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
          const Icon(Icons.directions_run, size: 48, color: AppColors.warmBrown),
          const SizedBox(height: 16),
          Text(
            'What can I help you with?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'I know your training history and can manage your schedule',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                onTap: () => onQuickAction('I want to create a training plan for an upcoming race'),
              ),
              QuickActionCard(
                emoji: '\u{1F504}',
                title: 'Adjust my schedule',
                subtitle: "Modify this week's plan",
                onTap: () => onQuickAction("Can you adjust this week's training schedule?"),
              ),
              QuickActionCard(
                emoji: '\u{1F4CA}',
                title: 'Analyze my progress',
                subtitle: 'How am I trending?',
                onTap: () => onQuickAction('How is my training going? Give me an analysis of my progress.'),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask your coach...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: AppColors.warmBrown,
          ),
        ],
      ),
    );
  }
}
