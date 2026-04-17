import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_message.dart';
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

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    // Role label
    children.add(_RoleLabel(isUser: _isUser));
    children.add(const SizedBox(height: 8));

    if (_isThinking) {
      children.add(ThinkingCard(label: _thinkingLabel(message.toolIndicator)));
    } else if (message.content.isNotEmpty || message.streaming) {
      children.add(_Bubble(message: message));
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

String _thinkingLabel(String? toolIndicator) {
  final trimmed = toolIndicator?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Working on your plan';
  return trimmed.replaceFirst(RegExp(r'[…\.]+$'), '');
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
      return Text('You', style: labelStyle);
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
        Text('RunCore AI Coach', style: labelStyle),
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
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: textColor,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
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
            if (message.streaming && message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _BlinkingCaret(
                  key: const Key('streaming-caret'),
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  final Color color;
  const _BlinkingCaret({super.key, required this.color});

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        '\u{2589}',
        style: TextStyle(fontSize: 14, color: widget.color),
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
            detail,
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.refresh,
                  size: 14,
                  color: AppColors.tertiary,
                ),
                SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
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
