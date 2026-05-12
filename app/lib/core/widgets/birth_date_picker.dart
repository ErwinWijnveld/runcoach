import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';

/// Cupertino-native DOB picker, used wherever the runner needs to give
/// us their date of birth (onboarding zones step + "Recompute" button on
/// HeartRateZonesSheet). Wraps a `CupertinoDatePicker` in date-only mode
/// inside a modal popup with a header (title, Cancel, Done).
///
/// [initial] prefills the picker — typically with HealthKit's DOB first,
/// then the user's saved `dateOfBirth`. When null, defaults to "30
/// years ago today" so the wheel lands on a reasonable starting point.
///
/// Returns the picked date on Done, null on Cancel.
Future<DateTime?> showBirthDatePickerSheet(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  // Apple won't let you create accounts under 13. We allow down to 5
  // for the parent-child use case. The wheel must reject anything past
  // this — using `today` as `maximumDate` would let the runner pick
  // (today.year - 5, later month/day) which is still under 5 years old.
  final maxDate = DateTime(now.year - 5, now.month, now.day);
  final minDate = DateTime(1900, 1, 1);
  final defaultInitial = DateTime(now.year - 30, now.month, now.day);

  // Clamp the initial so the picker never starts at an invalid date.
  DateTime startDate = initial ?? defaultInitial;
  if (startDate.isAfter(maxDate)) startDate = maxDate;
  if (startDate.isBefore(minDate)) startDate = minDate;

  DateTime picked = startDate;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) {
      return Container(
        height: 320,
        color: AppColors.neutral,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header: Cancel | Title | Done. Mirrors the iOS native
              // datepicker pattern so users feel at home.
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.inputBorder, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        ctx.l10n.commonCancel,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ctx.l10n.birthDatePickerTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryInk,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // Strip time so callers get a pure date.
                        final result = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                        Navigator.of(ctx).pop(result);
                      },
                      child: Text(
                        ctx.l10n.birthDatePickerDone,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: startDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  maximumYear: maxDate.year,
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
