import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
                // Swallow taps inside the sheet so they don't dismiss.
                onTap: () {},
                child: Container(
                  height: size.height * 0.85,
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                          emptyStateTitle: 'Ask about this workout',
                          emptyStateSubtitle:
                              'I know your target stats, splits, and how it fits this week.',
                          emptyStateSuggestions: const [
                            (
                              icon: CupertinoIcons.wrench_fill,
                              label: 'Adjust this workout',
                              subtitle: 'Distance, pace, intervals.',
                              prompt:
                                  'Can we tweak this workout? I\'d like to ',
                            ),
                            (
                              icon: CupertinoIcons.info_circle_fill,
                              label: 'What\'s the point?',
                              subtitle: 'Why this workout, why today.',
                              prompt:
                                  'What\'s the purpose of this workout and what should I focus on?',
                            ),
                            (
                              icon: CupertinoIcons.timer_fill,
                              label: 'Pace check',
                              subtitle: 'Is the target pace right for me?',
                              prompt:
                                  'Is the target pace realistic based on my recent runs?',
                            ),
                            (
                              icon: CupertinoIcons.calendar_today,
                              label: 'Move it',
                              subtitle: 'Reschedule to another day.',
                              prompt: 'Can we move this workout to ',
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
                'Close',
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
