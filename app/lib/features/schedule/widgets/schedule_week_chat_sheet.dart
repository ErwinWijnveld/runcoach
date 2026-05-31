import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/coach_chat_view.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/providers/schedule_week_chat_provider.dart';
import 'package:app/features/schedule/utils/week_chat_suggestions.dart';
import 'package:app/features/schedule/widgets/schedule_week_context_pill.dart';

/// Backdrop-blur overlay hosting a RunCoachAgent chat scoped to one
/// training week. Mirrors [WorkoutChatSheet]'s shell but uses the
/// regular coach endpoints so the conversation appears in the chats
/// list once it's lazy-created on first send.
class ScheduleWeekChatSheet {
  static Future<void> show(BuildContext context, TrainingWeek week) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.scheduleChatBarrierLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _ScheduleWeekChatOverlay(week: week),
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

class _ScheduleWeekChatOverlay extends ConsumerWidget {
  final TrainingWeek week;

  const _ScheduleWeekChatOverlay({required this.week});

  String _formatDateRange(BuildContext context) {
    final start = DateTime.tryParse(week.startsAt);
    if (start == null) return '';
    final end = start.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.MMMd(locale);
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final baseHeight = size.height * 0.85;
    final sheetHeight = (baseHeight - keyboardInset).clamp(
      size.height * 0.5,
      baseHeight,
    );

    final dateRange = _formatDateRange(context);
    final title = context.l10n.scheduleChatTitle(week.weekNumber, dateRange);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final suggestions = weekChatSuggestions(context.l10n, localeTag, week);

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
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ScheduleWeekContextPill(
                            weekNumber: week.weekNumber,
                            startsAtIso: week.startsAt,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CoachChatView(
                          // CoachChatView uses conversationId only for
                          // its widget key; the provider tracks the real
                          // UUID internally and creates it on first send.
                          conversationId: 'week-${week.id}',
                          watchMessages: (r) => r.watch(
                            scheduleWeekChatProvider(week.id, title),
                          ),
                          sendMessage: (r, text, {chipValue}) => r
                              .read(
                                scheduleWeekChatProvider(week.id, title)
                                    .notifier,
                              )
                              .sendMessage(text, chipValue: chipValue),
                          onRetry: (r, messageId) => r
                              .read(
                                scheduleWeekChatProvider(week.id, title)
                                    .notifier,
                              )
                              .retry(messageId),
                          onInvalidate: (r) => r.invalidate(
                            scheduleWeekChatProvider(week.id, title),
                          ),
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
                          emptyStateTitle: context.l10n.scheduleChatEmptyTitle,
                          emptyStateSubtitle:
                              context.l10n.scheduleChatEmptySubtitle,
                          emptyStateSuggestions: suggestions
                              .map(
                                (s) => (
                                  icon: s.icon,
                                  label: s.label,
                                  subtitle: s.subtitle,
                                  prompt: s.prompt,
                                ),
                              )
                              .toList(growable: false),
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
