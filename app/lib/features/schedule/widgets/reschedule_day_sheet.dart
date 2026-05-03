import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/services/workout_scheduler_service.dart';

/// Cupertino-style modal that lets the runner pick a new date for a training
/// day. Today renders with a gold ring, the picked date with a filled brown
/// disc — no Material ripples or hard-rounded squares. On save, calls the
/// backend and invalidates schedule providers so every screen reflects the
/// move.
class RescheduleDaySheet extends ConsumerStatefulWidget {
  final int dayId;
  final DateTime initialDate;
  final DateTime? lastDate;
  final VoidCallback? onRescheduled;

  const RescheduleDaySheet({
    super.key,
    required this.dayId,
    required this.initialDate,
    required this.lastDate,
    this.onRescheduled,
  });

  static Future<void> show(
    BuildContext context, {
    required int dayId,
    required DateTime initialDate,
    DateTime? lastDate,
    VoidCallback? onRescheduled,
  }) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => RescheduleDaySheet(
        dayId: dayId,
        initialDate: initialDate,
        lastDate: lastDate,
        onRescheduled: onRescheduled,
      ),
    );
  }

  @override
  ConsumerState<RescheduleDaySheet> createState() => _RescheduleDaySheetState();
}

class _RescheduleDaySheetState extends ConsumerState<RescheduleDaySheet> {
  late DateTime _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final today = _ymd(DateTime.now());
    final initial = _ymd(widget.initialDate);
    _selected = initial.isBefore(today) ? today : initial;
  }

  static DateTime _ymd(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(rescheduleDayProvider.notifier)
          .reschedule(dayId: widget.dayId, date: _selected);

      // Best-effort sync: if a watch workout was already scheduled for this
      // training day, move it to the new date too. Silent no-op otherwise.
      //
      // Awaited intentionally: a fire-and-forget call here would race with
      // a quick follow-up Send-to-watch tap (both ops would read the same
      // pre-move state, both would try to schedule, and we'd end up with
      // two entries). The native call short-circuits when nothing's on the
      // watch, so the cost is sub-second on the cold path.
      await ref.read(workoutSchedulerServiceProvider).rescheduleIfPresent(
            dayId: widget.dayId,
            newDate: _selected,
          );

      if (!mounted) return;
      // RescheduleDay notifier already bumps planVersion, which invalidates
      // every plan-derived provider (schedule, current week, day detail).
      widget.onRescheduled?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not reschedule'),
          content: Text('$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _ymd(DateTime.now());
    var lastDate = widget.lastDate != null
        ? _ymd(widget.lastDate!)
        : today.add(const Duration(days: 365));
    // Defensive: if the caller's lastDate is in the past (or before today)
    // the calendar would have firstDate > lastDate and crash. Fall back to
    // the 1-year cutoff in that case.
    if (lastDate.isBefore(today)) {
      lastDate = today.add(const Duration(days: 365));
    }
    // Clamp the selection to the visible range so the displayMonth lands on
    // a real, navigable month even when the initialDate is outside [today,
    // lastDate].
    if (_selected.isAfter(lastDate)) {
      _selected = lastDate;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _Header(onCancel: () => Navigator.of(context).pop()),
            const SizedBox(height: 4),
            _CupertinoCalendar(
              selected: _selected,
              firstDate: today,
              lastDate: lastDate,
              today: today,
              onDateChanged: (d) => setState(() => _selected = d),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _busy ? null : _save,
                  borderRadius: BorderRadius.circular(14),
                  child: _busy
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(
                          'Move to ${_formatHumanDate(_selected)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatHumanDate(DateTime d) {
    return '${_weekday(d)} ${d.day} ${_monthShort(d.month)}';
  }

  static String _weekday(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  static String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCancel;
  const _Header({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: GoogleFonts.publicSans(
                fontSize: 15,
                color: AppColors.tertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Reschedule',
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          // Visual balancer for the Cancel button so the title centers properly.
          const SizedBox(width: 76),
        ],
      ),
    );
  }
}

/// Month-grid calendar styled to match the rest of the app. Today gets a gold
/// ring (`AppColors.secondary`); the selected date is a filled brown disc
/// (`AppColors.primary`) with white text. Out-of-range and out-of-month dates
/// are muted and non-tappable. Weeks start on Monday.
class _CupertinoCalendar extends StatefulWidget {
  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateChanged;

  const _CupertinoCalendar({
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.onDateChanged,
  });

  @override
  State<_CupertinoCalendar> createState() => _CupertinoCalendarState();
}

class _CupertinoCalendarState extends State<_CupertinoCalendar> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(widget.selected.year, widget.selected.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(
        _displayMonth.year,
        _displayMonth.month + delta,
      );
    });
  }

  bool _canGoPrev() {
    final firstOfDisplay = DateTime(_displayMonth.year, _displayMonth.month);
    final firstOfBound =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    return firstOfDisplay.isAfter(firstOfBound);
  }

  bool _canGoNext() {
    final firstOfDisplay = DateTime(_displayMonth.year, _displayMonth.month);
    final firstOfBound =
        DateTime(widget.lastDate.year, widget.lastDate.month);
    return firstOfDisplay.isBefore(firstOfBound);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          _MonthHeader(
            month: _displayMonth,
            canPrev: _canGoPrev(),
            canNext: _canGoNext(),
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 8),
          const _WeekdayRow(),
          const SizedBox(height: 4),
          _MonthGrid(
            displayMonth: _displayMonth,
            selected: widget.selected,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            today: widget.today,
            onDateTap: widget.onDateChanged,
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          '${_monthLong(month.month)} ${month.year}',
          style: GoogleFonts.ebGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: AppColors.primaryInk,
          ),
        ),
        const Spacer(),
        _ChevronButton(
          icon: CupertinoIcons.chevron_left,
          onPressed: canPrev ? onPrev : null,
        ),
        const SizedBox(width: 4),
        _ChevronButton(
          icon: CupertinoIcons.chevron_right,
          onPressed: canNext ? onNext : null,
        ),
      ],
    );
  }

  static String _monthLong(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _ChevronButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(32, 32),
      onPressed: onPressed,
      child: Icon(
        icon,
        size: 18,
        color: disabled
            ? AppColors.inkMuted.withValues(alpha: 0.4)
            : AppColors.primaryInk,
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final style = GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: AppColors.inkMuted,
    );
    return Row(
      children: [
        for (final l in labels)
          Expanded(child: Center(child: Text(l, style: style))),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateTap;

  const _MonthGrid({
    required this.displayMonth,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(displayMonth.year, displayMonth.month);
    // Monday = 1 ... Sunday = 7. Offset to put Monday in column 0.
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0)
        .day;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        for (var row = 0; row < totalCells / 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(row * 7 + col, leadingBlanks, daysInMonth),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int cellIndex, int leadingBlanks, int daysInMonth) {
    final dayOfMonth = cellIndex - leadingBlanks + 1;
    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
      return const SizedBox(height: 44);
    }

    final cellDate =
        DateTime(displayMonth.year, displayMonth.month, dayOfMonth);
    final isSelected = _sameDay(cellDate, selected);
    final isToday = _sameDay(cellDate, today);
    final disabled = cellDate.isBefore(firstDate) || cellDate.isAfter(lastDate);

    return _DateCell(
      day: dayOfMonth,
      isSelected: isSelected,
      isToday: isToday,
      disabled: disabled,
      onTap: disabled ? null : () => onDateTap(cellDate),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool disabled;
  final VoidCallback? onTap;

  const _DateCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (disabled) {
      textColor = AppColors.inkMuted.withValues(alpha: 0.4);
    } else if (isSelected) {
      textColor = AppColors.neutral;
    } else if (isToday) {
      textColor = AppColors.secondary;
    } else {
      textColor = AppColors.primaryInk;
    }

    BoxDecoration? decoration;
    if (isSelected) {
      decoration = const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondary, width: 1.5),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: decoration,
            child: Text(
              '$day',
              style: GoogleFonts.publicSans(
                fontSize: 15,
                fontWeight:
                    (isSelected || isToday) ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
