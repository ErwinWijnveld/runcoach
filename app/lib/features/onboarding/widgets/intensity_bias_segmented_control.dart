import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';

/// Three-segment selector for `IntensityBias`. Selected segment uses the
/// inverted dark-on-cream palette; unselected segments are white cards
/// with the standard `inputBorder`. Under the "Standard" segment a tiny
/// `(auto-pick)` label fades in/out depending on selection.
class IntensityBiasSegmentedControl extends StatelessWidget {
  final IntensityBias selected;
  final ValueChanged<IntensityBias> onChanged;

  const IntensityBiasSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final option in IntensityBias.values) ...[
              Expanded(
                child: _Segment(
                  label: _labelFor(option),
                  selected: option == selected,
                  onTap: () => onChanged(option),
                ),
              ),
              if (option != IntensityBias.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected == IntensityBias.standard ? 1.0 : 0.0,
                child: Text(
                  '(auto-pick)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  static String _labelFor(IntensityBias bias) => switch (bias) {
        IntensityBias.takeItEasy => 'Take it easy',
        IntensityBias.standard => 'Standard',
        IntensityBias.pushMeHarder => 'Push me harder',
      };
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryInk : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryInk : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.cream : AppColors.primaryInk,
          ),
        ),
      ),
    );
  }
}
