import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';

/// The canonical primary CTA used across every onboarding step:
/// 56pt height, 16-radius, `primaryInk` background, uppercase caps label
/// (`RunCoreText.buttonCaps` with letterSpacing 1.4) on a `neutral` fill.
///
/// Lives once here so the four screens that need it (connect-health,
/// overview, zones, the form's step scaffold) stay visually identical
/// without copy-pasted styling drifting per surface. When [enabled] is
/// false, the button fades to 35% opacity and `onPressed` is null —
/// matches the form's per-step "next" gating behaviour.
class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.35,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isEnabled ? onTap : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryInk,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: RunCoreText.buttonCaps(color: AppColors.neutral).copyWith(
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
