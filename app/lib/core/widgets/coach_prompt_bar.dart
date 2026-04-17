import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, InkWell;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/animated_typing_text.dart';

/// The warm pill that reads "Ask your coach...". Used both as the dashboard
/// entry point (tap to navigate) and as the chat screen's actual input.
class CoachPromptBar extends StatelessWidget {
  const CoachPromptBar.navigate({
    super.key,
    required VoidCallback this.onTap,
  })  : controller = null,
        focusNode = null,
        onSubmit = null,
        sending = false,
        autofocus = false,
        animatedSuggestions = null;

  const CoachPromptBar.navigateAnimated({
    super.key,
    required VoidCallback this.onTap,
    required List<String> this.animatedSuggestions,
  })  : controller = null,
        focusNode = null,
        onSubmit = null,
        sending = false,
        autofocus = false;

  const CoachPromptBar.input({
    super.key,
    required TextEditingController this.controller,
    required ValueChanged<String> this.onSubmit,
    this.focusNode,
    this.sending = false,
    this.autofocus = false,
  })  : onTap = null,
        animatedSuggestions = null;

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmit;
  final bool sending;
  final bool autofocus;
  final List<String>? animatedSuggestions;

  bool get _isInput => controller != null;

  @override
  Widget build(BuildContext context) {
    if (_isInput) {
      return _InputBar(
        controller: controller!,
        focusNode: focusNode,
        onSubmit: onSubmit!,
        sending: sending,
        autofocus: autofocus,
      );
    }
    return _NavigateBar(
      onTap: onTap!,
      animatedSuggestions: animatedSuggestions,
    );
  }
}

class _NavigateBar extends StatelessWidget {
  final VoidCallback onTap;
  final List<String>? animatedSuggestions;

  const _NavigateBar({required this.onTap, this.animatedSuggestions});

  @override
  Widget build(BuildContext context) {
    final placeholder = animatedSuggestions != null && animatedSuggestions!.isNotEmpty
        ? AnimatedTypingText(
            suggestions: animatedSuggestions!,
            style: RunCoreText.body(),
          )
        : Text('Ask your coach...', style: RunCoreText.body());

    return Material(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _promptDecoration(),
          child: Row(
            children: [
              const _StarIcon(),
              const SizedBox(width: 12),
              Expanded(child: placeholder),
              const SizedBox(width: 12),
              const _SendIcon(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSubmit;
  final bool sending;
  final bool autofocus;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.sending,
    required this.autofocus,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    widget.onSubmit(text);
  }

  void _focusField() {
    if (widget.sending) return;
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = hasText && !widget.sending;

    return Material(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusField,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _promptDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _StarIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  placeholder: 'Ask your coach...',
                  placeholderStyle: RunCoreText.body(),
                  style: RunCoreText.body(
                    color: AppColors.primaryInk,
                    weight: FontWeight.w400,
                  ),
                  decoration: null,
                  padding: EdgeInsets.zero,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  autofocus: widget.autofocus,
                  enabled: !widget.sending,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                height: 28,
                child: widget.sending
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 8),
                      )
                    : Opacity(
                        opacity: canSend ? 1.0 : 0.4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: canSend ? _submit : null,
                          child: const _SendIcon(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _promptDecoration() {
  return BoxDecoration(
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(24),
    gradient: RadialGradient(
      center: Alignment.centerRight,
      radius: 3.5,
      colors: [
        AppColors.secondary.withValues(alpha: 0.15),
        AppColors.secondary.withValues(alpha: 0.0),
      ],
    ),
  );
}

class _StarIcon extends StatelessWidget {
  const _StarIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/coach_prompt_star.svg',
      width: 18,
      height: 19,
    );
  }
}

class _SendIcon extends StatelessWidget {
  const _SendIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/coach_send.svg',
      width: 28,
      height: 28,
    );
  }
}
