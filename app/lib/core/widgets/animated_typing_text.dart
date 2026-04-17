import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

/// Cycles through [suggestions], typing each one letter-by-letter, pausing,
/// deleting, then moving to the next. Used to hint at what the user can ask
/// the coach without making the placeholder feel stale.
///
/// Caret is intentionally not drawn — the bar's own input caret (or absence
/// of one for the navigate variant) keeps the visual clean.
class AnimatedTypingText extends StatefulWidget {
  final List<String> suggestions;
  final TextStyle? style;

  /// Delay between individual typed characters.
  final Duration typeSpeed;

  /// Delay between deleted characters (typically faster than typing).
  final Duration deleteSpeed;

  /// How long to hold a fully-typed suggestion before deleting.
  final Duration holdDuration;

  /// Idle pause between suggestions (after delete, before next type).
  final Duration pauseBetween;

  const AnimatedTypingText({
    super.key,
    required this.suggestions,
    this.style,
    this.typeSpeed = const Duration(milliseconds: 45),
    this.deleteSpeed = const Duration(milliseconds: 20),
    this.holdDuration = const Duration(milliseconds: 1800),
    this.pauseBetween = const Duration(milliseconds: 350),
  });

  @override
  State<AnimatedTypingText> createState() => _AnimatedTypingTextState();
}

class _AnimatedTypingTextState extends State<AnimatedTypingText> {
  int _suggestionIndex = 0;
  int _charCount = 0;
  bool _deleting = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _schedule(widget.pauseBetween);
  }

  @override
  void didUpdateWidget(covariant AnimatedTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.suggestions, widget.suggestions)) {
      _tick?.cancel();
      setState(() {
        _suggestionIndex = 0;
        _charCount = 0;
        _deleting = false;
      });
      _schedule(widget.pauseBetween);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _schedule(Duration delay) {
    _tick?.cancel();
    _tick = Timer(delay, _advance);
  }

  void _advance() {
    if (!mounted || widget.suggestions.isEmpty) return;

    final current = widget.suggestions[_suggestionIndex % widget.suggestions.length];

    if (!_deleting) {
      if (_charCount < current.length) {
        setState(() => _charCount++);
        _schedule(widget.typeSpeed);
      } else {
        _schedule(widget.holdDuration);
        _deleting = true;
      }
      return;
    }

    if (_charCount > 0) {
      setState(() => _charCount--);
      _schedule(widget.deleteSpeed);
    } else {
      _deleting = false;
      _suggestionIndex++;
      _schedule(widget.pauseBetween);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = widget.suggestions[_suggestionIndex % widget.suggestions.length];
    final visible = current.substring(0, _charCount);

    return Text(
      visible.isEmpty ? ' ' : visible,
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
    );
  }
}
