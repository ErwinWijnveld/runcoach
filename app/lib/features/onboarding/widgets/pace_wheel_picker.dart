import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';

/// Cupertino bottom-sheet with a dual-wheel picker for selecting an easy-run
/// pace in mm:ss/km. Minutes 3-12, seconds in steps of 5. Returns the chosen
/// total seconds when the user taps Done; returns null on Cancel or dismiss.
Future<int?> showPaceWheelPicker(
  BuildContext context, {
  required int initialSecondsPerKm,
}) async {
  final clamped = initialSecondsPerKm.clamp(180, 12 * 60 + 55);
  final initialMinutes = (clamped ~/ 60).clamp(3, 12);
  final initialSecondsRaw = clamped % 60;
  final initialSecondsIndex = (initialSecondsRaw ~/ 5).clamp(0, 11);

  int minutes = initialMinutes;
  int secondsIndex = initialSecondsIndex;

  return showCupertinoModalPopup<int>(
    context: context,
    builder: (sheetContext) {
      return Container(
        height: 320,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHeader(
              onCancel: () => Navigator.of(sheetContext).pop(),
              onDone: () => Navigator.of(sheetContext).pop(minutes * 60 + secondsIndex * 5),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 36,
                      scrollController: FixedExtentScrollController(initialItem: initialMinutes - 3),
                      onSelectedItemChanged: (i) => minutes = i + 3,
                      children: List<Widget>.generate(10, (i) {
                        return Center(
                          child: Text(
                            '${i + 3}',
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ),
                  ),
                  Text(':', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500)),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 36,
                      scrollController: FixedExtentScrollController(initialItem: initialSecondsIndex),
                      onSelectedItemChanged: (i) => secondsIndex = i,
                      children: List<Widget>.generate(12, (i) {
                        final seconds = i * 5;
                        return Center(
                          child: Text(
                            seconds.toString().padLeft(2, '0'),
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'per kilometer',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDone;
  const _SheetHeader({required this.onCancel, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel,
            child: Text(
              context.l10n.commonCancel,
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                context.l10n.paceWheelPickerTitle,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDone,
            child: Text(
              context.l10n.paceWheelPickerDone,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryInk),
            ),
          ),
        ],
      ),
    );
  }
}
