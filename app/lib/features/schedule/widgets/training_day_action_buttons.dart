import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ElevatedButton;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

/// State-aware action row under the stat tiles.
/// - missed / today / upcoming: Send to watch + Pick activity (side by side)
/// - completed: Send to watch (full-width)
class TrainingDayActionButtons extends StatelessWidget {
  final TrainingDayStatus status;
  final VoidCallback? onSendToWatch;
  final VoidCallback? onSelectActivity;

  const TrainingDayActionButtons({
    super.key,
    required this.status,
    required this.onSendToWatch,
    required this.onSelectActivity,
  });

  @override
  Widget build(BuildContext context) {
    final sendToWatch = _PrimaryButton(
      label: 'SEND TO WATCH',
      onPressed: onSendToWatch,
    );

    if (!status.showSelectActivity) {
      return SizedBox(width: double.infinity, child: sendToWatch);
    }

    return Row(
      children: [
        Expanded(child: sendToWatch),
        const SizedBox(width: 8),
        Expanded(
          child: _PrimaryButton(
            label: 'PICK ACTIVITY',
            onPressed: onSelectActivity,
          ),
        ),
      ],
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
