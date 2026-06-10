import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// The brand-gold primary CTA used by edit modals (save / confirm buttons).
/// Full-width gold pill with an uppercase Space Grotesk label — same visual
/// language as the share-card CTA. Shows a spinner while [busy]; a null
/// [onPressed] renders dimmed and inert.
class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled || busy ? 1.0 : 0.5,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
          child: busy
              ? const CupertinoActivityIndicator(color: AppColors.neutral)
              : Text(
                  label.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}
