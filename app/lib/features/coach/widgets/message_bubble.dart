import 'package:flutter/cupertino.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_message.dart';

class MessageBubble extends StatelessWidget {
  final CoachMessage message;
  final VoidCallback? onRetry;

  const MessageBubble({super.key, required this.message, this.onRetry});

  bool get _isUser => message.role == 'user';
  bool get _failed => message.errorDetail != null;

  @override
  Widget build(BuildContext context) {
    final textColor =
        _isUser ? CupertinoColors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment:
          _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: _isUser ? 60 : 0,
              right: _isUser ? 0 : 60,
              bottom: _failed ? 4 : 8,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isUser ? AppColors.warmBrown : AppColors.lightTan,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(_isUser ? 18 : 4),
                bottomRight: Radius.circular(_isUser ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isUser)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'COACH',
                      style: TextStyle(
                        color: AppColors.warmBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (_isUser)
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.35,
                    ),
                  )
                else if (message.content.isNotEmpty)
                  GptMarkdown(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                if (message.streaming)
                  Padding(
                    padding: EdgeInsets.only(
                      top: message.content.isEmpty ? 0 : 2,
                    ),
                    child: _BlinkingCaret(
                      key: const Key('streaming-caret'),
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (message.toolIndicator != null)
          Padding(
            key: const Key('tool-indicator-pill'),
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CupertinoActivityIndicator(radius: 6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.toolIndicator!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_failed)
          _ErrorStrip(detail: message.errorDetail!, onRetry: onRetry),
      ],
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
      child: Text('▍', style: TextStyle(fontSize: 14, color: widget.color)),
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String detail;
  final VoidCallback? onRetry;

  const _ErrorStrip({required this.detail, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 60),
      child: Row(
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
                    color: AppColors.warmBrown,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warmBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
