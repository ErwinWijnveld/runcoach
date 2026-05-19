import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/utils/coach_error_codes.dart';
import 'package:app/features/coach/widgets/chip_suggestions_row.dart';
import 'package:app/features/coach/widgets/stats_card_bubble.dart';
import 'package:app/features/coach/widgets/thinking_card.dart';

class MessageBubble extends StatelessWidget {
  final CoachMessage message;
  final VoidCallback? onRetry;
  final void Function(String label, String value)? onChipTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onChipTap,
  });

  bool get _isUser => message.role == 'user';
  bool get _failed => message.errorDetail != null;

  bool get _isThinking =>
      !_isUser &&
      message.streaming &&
      message.content.isEmpty &&
      message.statsCard == null &&
      message.chips == null;

  bool get _isToolRunning =>
      !_isUser && message.streaming && message.toolIndicator != null;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Role label
    children.add(_RoleLabel(isUser: _isUser));
    children.add(const SizedBox(height: 8));

    if (_isThinking) {
      children.add(ThinkingCard(label: _thinkingLabel(context, message.toolIndicator)));
    } else if (message.content.isNotEmpty || message.streaming) {
      children.add(_Bubble(message: message));
      if (_isToolRunning) {
        children.add(const SizedBox(height: 8));
        children.add(
          ThinkingCard(label: _thinkingLabel(context, message.toolIndicator)),
        );
      }
    }

    if (message.statsCard != null) {
      children.add(const SizedBox(height: 8));
      children.add(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 296),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: StatsCardBubble(metrics: message.statsCard!.metrics),
          ),
        ),
      );
    }

    if (message.chips != null && message.chips!.isNotEmpty) {
      children.add(const SizedBox(height: 16));
      children.add(const Align(
        alignment: Alignment.centerRight,
        child: _RoleLabel(isUser: true),
      ));
      children.add(const SizedBox(height: 8));
      children.add(ChipSuggestionsRow(
        chips: message.chips!
            .map((c) => <String, dynamic>{'label': c.label, 'value': c.value})
            .toList(),
        onTap: onChipTap ?? (_, _) {},
      ));
    }

    if (_failed) {
      children.add(const SizedBox(height: 4));
      children.add(_ErrorStrip(detail: message.errorDetail!, onRetry: onRetry));
    }

    if (children.length <= 2) {
      // Only role label and spacer, nothing to show
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: children,
    );
  }
}

String _thinkingLabel(BuildContext context, String? toolIndicator) {
  final l10n = context.l10n;
  final trimmed = toolIndicator?.trim();
  if (trimmed == null || trimmed.isEmpty) return l10n.coachThinking;
  // If this is a raw tool name from the SSE stream, map to a localized label.
  final mapped = switch (trimmed) {
    'Thinking' => l10n.coachThinking,
    'GetRecentRuns' => l10n.toolIndicatorGetRecentRuns,
    'SearchStravaActivities' => l10n.toolIndicatorSearchActivities,
    'SearchActivities' => l10n.toolIndicatorSearchActivities,
    'GetActivityDetails' => l10n.toolIndicatorGetActivityDetails,
    'GetCurrentSchedule' => l10n.toolIndicatorGetCurrentSchedule,
    'GetGoalInfo' => l10n.toolIndicatorGetGoalInfo,
    'GetComplianceReport' => l10n.toolIndicatorGetComplianceReport,
    'CreateSchedule' => l10n.toolIndicatorCreateSchedule,
    'EditSchedule' => l10n.toolIndicatorEditSchedule,
    'ModifySchedule' => l10n.toolIndicatorModifySchedule,
    'GetCurrentProposal' => l10n.toolIndicatorGetCurrentProposal,
    'GetRunningProfile' => l10n.toolIndicatorGetRunningProfile,
    'PresentRunningStats' => l10n.toolIndicatorPresentRunningStats,
    'OfferChoices' => l10n.toolIndicatorOfferChoices,
    'EditWorkout' => l10n.toolIndicatorEditWorkout,
    'RescheduleWorkout' => l10n.toolIndicatorRescheduleWorkout,
    'EscalateToCoach' => l10n.toolIndicatorEscalateToCoach,
    _ => null,
  };
  final label = mapped ?? trimmed;
  return label.replaceFirst(RegExp(r'[…\.]+$'), '');
}

class _RoleLabel extends StatelessWidget {
  final bool isUser;
  const _RoleLabel({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.eyebrow,
      height: 15 / 10,
    );

    if (isUser) {
      return Text(context.l10n.coachRoleYou, style: labelStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/coach_prompt_star.svg',
          width: 11,
          height: 11,
        ),
        const SizedBox(width: 8),
        Text(context.l10n.coachRoleAssistant, style: labelStyle),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final CoachMessage message;
  const _Bubble({required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final maxWidth = _isUser ? 278.0 : 296.0;
    final textColor =
        _isUser ? const Color(0xFF745F27) : AppColors.primaryInk;

    final bodyStyle = GoogleFonts.publicSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: textColor,
    );

    final mediaQuery = MediaQuery.of(context);
    final clampedScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: MediaQuery(
        data: mediaQuery.copyWith(textScaler: clampedScaler),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _isUser ? const Color(0xFFFDEBBB) : CupertinoColors.white,
            border: _isUser ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(_isUser ? 24 : 0),
              topRight: Radius.circular(_isUser ? 0 : 24),
              bottomLeft: const Radius.circular(24),
              bottomRight: const Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUser)
                Text(message.content, style: bodyStyle)
              else if (message.content.isNotEmpty)
                GptMarkdown(message.content, style: bodyStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String detail;
  final VoidCallback? onRetry;

  const _ErrorStrip({required this.detail, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_circle,
          size: 14,
          color: AppColors.danger,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            localizedCoachError(context, detail),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.danger,
            ),
            textAlign: TextAlign.end,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(width: 4),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            onPressed: onRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.refresh,
                  size: 14,
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.coachMessageRetry,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
