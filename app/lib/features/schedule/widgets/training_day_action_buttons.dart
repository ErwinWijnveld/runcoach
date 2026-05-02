import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ElevatedButton;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

/// Single full-width "Send to watch" CTA. Other actions (pick activity,
/// reschedule) live in the top-right ellipsis menu so the primary CTA stays
/// uncontested. The status arg is kept for future per-state copy variations.
class TrainingDayActionButtons extends StatelessWidget {
  final TrainingDayStatus status;
  final VoidCallback? onSendToWatch;

  const TrainingDayActionButtons({
    super.key,
    required this.status,
    required this.onSendToWatch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _PrimaryButton(
        label: 'SEND TO WATCH',
        onPressed: onSendToWatch,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.neutral,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral,
        ),
      ),
    );
  }
}
