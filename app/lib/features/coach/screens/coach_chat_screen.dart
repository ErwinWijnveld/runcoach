import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/coach_chat_view.dart';

class CoachChatScreen extends ConsumerWidget {
  final String conversationId;
  const CoachChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: CoachChatView(
                  conversationId: conversationId,
                  watchMessages: (ref) =>
                      ref.watch(coachChatProvider(conversationId)),
                  sendMessage: (ref, text, {chipValue}) => ref
                      .read(coachChatProvider(conversationId).notifier)
                      .sendMessage(text, chipValue: chipValue),
                  onAccept: (ref, proposalId) async {
                    await ref
                        .read(coachChatProvider(conversationId).notifier)
                        .acceptProposal(proposalId);
                  },
                  onReject: (ref, proposalId) async {
                    await ref
                        .read(coachChatProvider(conversationId).notifier)
                        .rejectProposal(proposalId);
                  },
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
