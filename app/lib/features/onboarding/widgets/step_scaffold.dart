import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/onboarding/widgets/progress_dots.dart';

/// Layout used by every step of the onboarding form: back arrow + progress
/// dots at top, a serif title, optional subtitle, the step's content, and
/// a bottom "Continue" button that's disabled until the parent reports valid.
class StepScaffold extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final String continueLabel;
  final VoidCallback? onSkip;

  const StepScaffold({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.child,
    required this.canContinue,
    required this.onContinue,
    this.subtitle,
    this.onBack,
    this.continueLabel = 'CONTINUE',
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _BackChevron(onTap: onBack),
                    Expanded(
                      child: Center(
                        child: ProgressDots(total: stepCount, current: stepIndex),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: RunCoreText.serifTitle(size: 32).copyWith(height: 1.15),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onSkip != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: onSkip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _PrimaryButton(
                      label: continueLabel,
                      enabled: canContinue,
                      onTap: onContinue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackChevron extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackChevron({this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox(width: 36);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(36),
      onPressed: onTap,
      child: const Icon(CupertinoIcons.back, color: AppColors.primaryInk, size: 24),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onTap : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryInk,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
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
