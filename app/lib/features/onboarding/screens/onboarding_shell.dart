import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/coach_chat_view.dart';
import 'package:app/features/onboarding/providers/onboarding_chat_provider.dart';
import 'package:app/features/onboarding/providers/onboarding_provider.dart';

class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(onboardingConversationIdProvider);

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
              const _OnboardingTopBar(),
              Expanded(
                child: idAsync.when(
                  data: (id) => CoachChatView(
                    conversationId: id,
                    watchMessages: (ref) =>
                        ref.watch(onboardingChatProvider(id)),
                    sendMessage: (ref, text, {chipValue}) => ref
                        .read(onboardingChatProvider(id).notifier)
                        .sendMessage(text, chipValue: chipValue),
                    onAccept: (ref, proposalId) async {
                      await ref
                          .read(coachChatProvider(id).notifier)
                          .acceptProposal(proposalId);
                    },
                    onReject: (ref, proposalId) async {
                      await ref
                          .read(coachChatProvider(id).notifier)
                          .rejectProposal(proposalId);
                    },
                  ),
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (e, _) =>
                      Center(child: Text("Couldn't start onboarding: $e")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Center(
        child: RunCoreLogo(
          starSize: 22,
          textSize: 22,
          gap: 8,
        ),
      ),
    );
  }
}
