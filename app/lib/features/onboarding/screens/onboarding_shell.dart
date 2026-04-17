import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/coach/providers/coach_provider.dart'
    show coachChatProvider, proposalActionsProvider;
import 'package:app/features/coach/widgets/coach_chat_view.dart';

part 'onboarding_shell.g.dart';

@riverpod
Future<String> _onboardingConversationId(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.post('/onboarding/start');
  return (response.data as Map<String, dynamic>)['conversation_id'] as String;
}

class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(_onboardingConversationIdProvider);

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
              const SizedBox(
                height: 44,
                child: Center(
                  child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8),
                ),
              ),
              Expanded(
                child: idAsync.when(
                  data: (id) => _OnboardingAutoKickoff(
                    conversationId: id,
                    child: CoachChatView(
                      conversationId: id,
                      watchMessages: (ref) =>
                          ref.watch(coachChatProvider(id)),
                      sendMessage: (ref, text, {chipValue}) => ref
                          .read(coachChatProvider(id).notifier)
                          .sendMessage(text, chipValue: chipValue),
                      onAccept: (ref, proposalId) => ref
                          .read(proposalActionsProvider.notifier)
                          .accept(proposalId),
                      onReject: (ref, proposalId) => ref
                          .read(proposalActionsProvider.notifier)
                          .reject(proposalId),
                      onInvalidate: (ref) =>
                          ref.invalidate(coachChatProvider(id)),
                    ),
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

/// Sends an initial trigger message on first mount so the agent starts its
/// onboarding script. Subsequent mounts do nothing (the conversation already
/// has messages).
class _OnboardingAutoKickoff extends ConsumerStatefulWidget {
  final String conversationId;
  final Widget child;

  const _OnboardingAutoKickoff({
    required this.conversationId,
    required this.child,
  });

  @override
  ConsumerState<_OnboardingAutoKickoff> createState() =>
      _OnboardingAutoKickoffState();
}

class _OnboardingAutoKickoffState
    extends ConsumerState<_OnboardingAutoKickoff> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messages =
          await ref.read(coachChatProvider(widget.conversationId).future);
      if (messages.isEmpty && mounted) {
        await ref
            .read(coachChatProvider(widget.conversationId).notifier)
            .sendMessage('__onboarding_start__');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
