import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';

/// A single onboarding-baseline field with a lock-by-default pattern.
///
/// When `locked` is true the field is read-only and a lock icon is shown;
/// tapping the icon opens a confirmation dialog ("Override … data?"). On
/// "Edit anyway" the parent should set `locked: false` and the field
/// becomes tappable to invoke `onTapWhenUnlocked` (typically opens a
/// picker sheet or focuses a text field).
class LockedStatField extends StatelessWidget {
  final String label;
  final String valueText;
  final String? sourceLabel;
  final bool locked;
  final VoidCallback onUnlock;
  final VoidCallback onTapWhenUnlocked;

  const LockedStatField({
    super.key,
    required this.label,
    required this.valueText,
    required this.sourceLabel,
    required this.locked,
    required this.onUnlock,
    required this.onTapWhenUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: locked ? null : onTapWhenUnlocked,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
                if (locked)
                  GestureDetector(
                    onTap: () => _confirmUnlock(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      CupertinoIcons.lock_fill,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (sourceLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            locked
                ? context.l10n.lockedFieldFromSource(sourceLabel!)
                : context.l10n.lockedFieldEditedByYou,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmUnlock(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.lockedFieldOverrideTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.lockedFieldOverrideBody),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.lockedFieldEditAnyway),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onUnlock();
    }
  }
}
