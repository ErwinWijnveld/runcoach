import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/coach_chat_view.dart';
import 'package:app/features/schedule/providers/workout_chat_provider.dart';

/// Backdrop-blur overlay hosting the per-workout chat. Reuses the same
/// CoachChatView the main coach chat uses; differences live entirely in
/// the callbacks (workout provider for messages, handoff CTA for escalation).
class WorkoutChatSheet {
  static Future<void> show(BuildContext context, int trainingDayId) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close workout chat',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _WorkoutChatOverlay(trainingDayId: trainingDayId),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _WorkoutChatOverlay extends ConsumerWidget {
  final int trainingDayId;

  const _WorkoutChatOverlay({required this.trainingDayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Sheet height shrinks to make room for the keyboard so the input pill
    // (and the last few messages) stay visible. Floor at 50% of screen so
    // the chat doesn't collapse to nothing on landscape / split-view.
    final baseHeight = size.height * 0.85;
    final sheetHeight = (baseHeight - keyboardInset).clamp(
      size.height * 0.5,
      baseHeight,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: const Color(0x66000000),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: sheetHeight,
                  margin: EdgeInsets.fromLTRB(8, 0, 8, 8 + keyboardInset),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _SheetHandleBar(
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: CoachChatView(
                          // Conversation id is unknown until the first send
                          // creates one server-side. CoachChatView only uses
                          // it for keying retries; passing the day id as a
                          // string is safe because nothing else depends on
                          // it being a real UUID inside this sheet.
                          conversationId: 'workout-$trainingDayId',
                          watchMessages: (r) =>
                              r.watch(workoutChatProvider(trainingDayId)),
                          sendMessage: (r, text, {chipValue}) => r
                              .read(workoutChatProvider(trainingDayId).notifier)
                              .sendMessage(text, chipValue: chipValue),
                          onRetry: (r, messageId) => r
                              .read(workoutChatProvider(trainingDayId).notifier)
                              .retry(messageId),
                          onInvalidate: (r) =>
                              r.invalidate(workoutChatProvider(trainingDayId)),
                          onAccept: (r, proposalId) async {
                            await r
                                .read(proposalActionsProvider.notifier)
                                .accept(proposalId);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          onReject: (r, proposalId) => r
                              .read(proposalActionsProvider.notifier)
                              .reject(proposalId),
                          onHandoff: (r, prompt) async {
                            // Close the sheet first so the new chat owns
                            // the foreground; then start the coach chat.
                            Navigator.of(context).pop();
                            await startNewCoachChat(
                              context,
                              r,
                              seedMessage: prompt,
                            );
                          },
                          emptyStateTitle: context.l10n.workoutChatEmptyTitle,
                          emptyStateSubtitle: context.l10n.workoutChatEmptySubtitle,
                          emptyStateSuggestions: [
                            (
                              icon: CupertinoIcons.wrench_fill,
                              label: context.l10n.workoutChatAdjust,
                              subtitle: context.l10n.workoutChatAdjustSub,
                              prompt: context.l10n.workoutChatAdjustPrompt,
                            ),
                            (
                              icon: CupertinoIcons.info_circle_fill,
                              label: context.l10n.workoutChatWhatPlan,
                              subtitle: context.l10n.workoutChatWhatPlanSub,
                              prompt: context.l10n.workoutChatWhatPlanPrompt,
                            ),
                            (
                              icon: CupertinoIcons.timer_fill,
                              label: context.l10n.workoutChatPaceCheck,
                              subtitle: context.l10n.workoutChatPaceCheckSub,
                              prompt: context.l10n.workoutChatPaceCheckPrompt,
                            ),
                            (
                              icon: CupertinoIcons.calendar_today,
                              label: context.l10n.workoutChatMoveIt,
                              subtitle: context.l10n.workoutChatMoveItSub,
                              prompt: context.l10n.workoutChatMoveItPrompt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandleBar extends StatelessWidget {
  final VoidCallback onClose;
  const _SheetHandleBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              onPressed: onClose,
              child: Text(
                context.l10n.commonClose,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
