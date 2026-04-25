import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';
import 'package:app/features/coach/widgets/plan_details_sheet.dart';
import 'package:app/features/coach/widgets/proposal_card.dart';

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

  static const _suggestions = [
    (
      emoji: '\u{1F4C5}',
      label: 'Create a training plan',
      subtitle: 'For an upcoming race or new goal.',
      prompt: 'I want to create a training plan for an upcoming race',
    ),
    (
      emoji: '\u{1F504}',
      label: 'Adjust my schedule',
      subtitle: "Tweak this week's plan.",
      prompt: "Can you adjust this week's training schedule?",
    ),
    (
      emoji: '\u{1F4CA}',
      label: 'Analyze my progress',
      subtitle: 'How am I trending lately?',
      prompt: 'How is my training going? Give me an analysis of my progress.',
    ),
    (
      emoji: '\u{1F3C3}',
      label: 'Training advice',
      subtitle: 'Pacing, recovery, nutrition, gear.',
      prompt: 'Got any running advice for me today?',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What can I help you with?",
            style: RunCoreText.serifTitle(size: 32).copyWith(height: 1.15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'I know your training history and can manage your schedule.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          for (final s in _suggestions) ...[
            _SuggestionTile(
              emoji: s.emoji,
              label: s.label,
              subtitle: s.subtitle,
              onTap: () => onQuickAction(s.prompt),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
