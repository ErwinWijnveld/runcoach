import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

class ChoiceOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const ChoiceOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

/// Renders a column of tappable choice tiles with an optional "Other" row
/// beneath that expands to reveal a caller-provided input (text, number,
/// date…). Tapping a primary choice deselects "Other" and vice versa.
class ChoiceGroup<T> extends StatelessWidget {
  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final bool otherSelected;
  final VoidCallback? onOtherTapped;
  final String otherLabel;
  final Widget? otherChild;

  const ChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.otherSelected = false,
    this.onOtherTapped,
    this.otherLabel = 'Other',
    this.otherChild,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          _ChoiceTile(
            label: option.label,
            subtitle: option.subtitle,
            selected: !otherSelected && selected == option.value,
            onTap: () => onSelected(option.value),
          ),
          const SizedBox(height: 10),
        ],
        if (onOtherTapped != null) ...[
          _ChoiceTile(
            label: otherLabel,
            selected: otherSelected,
            onTap: onOtherTapped!,
          ),
          if (otherSelected && otherChild != null) ...[
            const SizedBox(height: 10),
            otherChild!,
          ],
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryInk : AppColors.cardBg;
    final borderColor = selected ? AppColors.primaryInk : AppColors.border;
    final textColor = selected ? AppColors.neutral : AppColors.primaryInk;
    final subtitleColor = selected ? AppColors.neutralHighlight : AppColors.inkMuted;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: subtitle != null ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(CupertinoIcons.check_mark, color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}
