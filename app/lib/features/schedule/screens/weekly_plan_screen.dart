import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_header.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/router/app_router.dart'
    show floatingPromptBarBottomOffset, kBottomStackedReservedHeight;
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/data/schedule_coach_suggestions.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/widgets/training_day_status.dart';

const _goldAccent = Color(0xFF785600);
const _labelMuted = Color(0xFF4F4535);

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return GradientScaffold(
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: dashboardAsync.when(
                    loading: () => const AppSpinner(),
                    error: (err, _) => AppErrorState(title: 'Error: $err'),
                    data: (dashboard) {
                      final race = dashboard.activeGoal;
                      if (race == null) {
                        return _EmptyState(onOpenGoals: () => context.go('/goals'));
                      }
                      final weeksAsync = ref.watch(scheduleProvider(race.id));
                      return weeksAsync.when(
                        loading: () => const AppSpinner(),
                        error: (err, _) => AppErrorState(title: 'Error: $err'),
                        data: (weeks) {
                          if (weeks.isEmpty) {
                            return const Center(
                              child: Text('No training week found'),
                            );
                          }
                          return _WeekPages(
                            weeks: weeks,
                            initialIndex: _initialWeekIndex(weeks),
                            onTapDay: (id) => context.go('/schedule/day/$id'),
                            onTapCoach: () => startNewCoachChat(context, ref),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: floatingPromptBarBottomOffset(context),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: CoachPromptBar.navigateAnimated(
                  onTap: () => startNewCoachChat(context, ref),
                  animatedSuggestions: scheduleCoachSuggestions,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onOpenGoals;
  const _EmptyState({required this.onOpenGoals});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.calendar,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No active goal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a goal (or ask the coach to build one) to see its schedule here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppFilledButton(label: 'Go to Goals', onPressed: onOpenGoals),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week pages (swipe + chevrons)
// ---------------------------------------------------------------------------

int? _todayWeekIndex(List<TrainingWeek> weeks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (int i = 0; i < weeks.length; i++) {
    final start = DateTime.tryParse(weeks[i].startsAt);
    if (start == null) continue;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = startDate.add(const Duration(days: 6));
    if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
      return i;
    }
  }
  return null;
}

int _initialWeekIndex(List<TrainingWeek> weeks) {
  final todayIdx = _todayWeekIndex(weeks);
  if (todayIdx != null) return todayIdx;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (int i = 0; i < weeks.length; i++) {
    final start = DateTime.tryParse(weeks[i].startsAt);
    if (start == null) continue;
    if (DateTime(start.year, start.month, start.day).isAfter(today)) {
      return i;
    }
  }
  return weeks.length - 1;
}

class _WeekPages extends StatefulWidget {
  final List<TrainingWeek> weeks;
  final int initialIndex;
  final ValueChanged<int> onTapDay;
  final VoidCallback onTapCoach;

  const _WeekPages({
    required this.weeks,
    required this.initialIndex,
    required this.onTapDay,
    required this.onTapCoach,
  });

  @override
  State<_WeekPages> createState() => _WeekPagesState();
}

class _WeekPagesState extends State<_WeekPages> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex.clamp(0, widget.weeks.length - 1),
  );
  late final _Highlight _highlight = _resolveHighlight(widget.weeks);
  late final int? _todayIdx = _todayWeekIndex(widget.weeks);
  late int _currentPage = widget.initialIndex.clamp(
    0,
    widget.weeks.length - 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    if (index < 0 || index >= widget.weeks.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayIdx = _todayIdx;
    final showBackToToday =
        todayIdx != null && _currentPage != todayIdx;
    return PageView.builder(
      controller: _controller,
      itemCount: widget.weeks.length,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, i) {
        return _WeekBody(
          week: widget.weeks[i],
          highlight: _highlight,
          canGoPrev: i > 0,
          canGoNext: i < widget.weeks.length - 1,
          onPrev: () => _animateTo(i - 1),
          onNext: () => _animateTo(i + 1),
          onBackToToday: showBackToToday
              ? () => _animateTo(todayIdx)
              : null,
          onTapDay: widget.onTapDay,
          onTapCoach: widget.onTapCoach,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Week body
// ---------------------------------------------------------------------------

class _WeekBody extends StatelessWidget {
  final TrainingWeek week;
  final _Highlight highlight;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onBackToToday;
  final ValueChanged<int> onTapDay;
  final VoidCallback onTapCoach;

  const _WeekBody({
    required this.week,
    required this.highlight,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onBackToToday,
    required this.onTapDay,
    required this.onTapCoach,
  });

  @override
  Widget build(BuildContext context) {
    final days = <TrainingDay>[...?week.trainingDays]..sort(
      (a, b) => a.order.compareTo(b.order),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _WeekHeader(
              week: week,
              canGoPrev: canGoPrev,
              canGoNext: canGoNext,
              onPrev: onPrev,
              onNext: onNext,
              onBackToToday: onBackToToday,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  _DayTile(
                    day: days[i],
                    highlight: highlight.dayId == days[i].id
                        ? highlight.kind
                        : _DayHighlight.none,
                    onTap: () => onTapDay(days[i].id),
                  ),
                  if (i < days.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: kBottomStackedReservedHeight),
        ],
      ),
    );
  }
}

enum _DayHighlight { none, today, upcoming }

class _Highlight {
  final int? dayId;
  final _DayHighlight kind;
  const _Highlight(this.dayId, this.kind);
  static const _Highlight empty = _Highlight(null, _DayHighlight.none);
}

_Highlight _resolveHighlight(List<TrainingWeek> weeks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  TrainingDay? todayDay;
  TrainingDay? nextFutureDay;
  DateTime? nextFutureDate;
  for (final week in weeks) {
    for (final d in week.trainingDays ?? const <TrainingDay>[]) {
      final parsed = DateTime.tryParse(d.date);
      if (parsed == null) continue;
      final date = DateTime(parsed.year, parsed.month, parsed.day);
      if (date == today) {
        todayDay = d;
      } else if (date.isAfter(today)) {
        if (nextFutureDate == null || date.isBefore(nextFutureDate)) {
          nextFutureDay = d;
          nextFutureDate = date;
        }
      }
    }
  }
  if (todayDay != null) return _Highlight(todayDay.id, _DayHighlight.today);
  if (nextFutureDay != null) {
    return _Highlight(nextFutureDay.id, _DayHighlight.upcoming);
  }
  return _Highlight.empty;
}

// ---------------------------------------------------------------------------
// Week header (week range + title + KM total)
// ---------------------------------------------------------------------------

class _WeekHeader extends StatelessWidget {
  final TrainingWeek week;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onBackToToday;

  const _WeekHeader({
    required this.week,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onBackToToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeekRangeRow(
                startsAt: week.startsAt,
                canGoPrev: canGoPrev,
                canGoNext: canGoNext,
                onPrev: onPrev,
                onNext: onNext,
                onBackToToday: onBackToToday,
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly Plan',
                style: RunCoreText.serifTitle(size: 38, height: 1.0),
              ),
            ],
          ),
        ),
        _KmTotal(km: week.totalKm),
      ],
    );
  }
}

class _WeekRangeRow extends StatelessWidget {
  final String startsAt;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onBackToToday;

  const _WeekRangeRow({
    required this.startsAt,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onBackToToday,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _format(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(startsAt);
    final label = start == null
        ? ''
        : '${_format(start)} - ${_format(start.add(const Duration(days: 6)))}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChevronButton(
          icon: Icons.chevron_left,
          enabled: canGoPrev,
          onTap: onPrev,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryInk,
          ),
        ),
        const SizedBox(width: 4),
        _ChevronButton(
          icon: Icons.chevron_right,
          enabled: canGoNext,
          onTap: onNext,
        ),
        if (onBackToToday != null) ...[
          const SizedBox(width: 8),
          _BackToTodayPill(onTap: onBackToToday!),
        ],
      ],
    );
  }
}

class _BackToTodayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackToTodayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryInk,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.today,
                size: 12,
                color: AppColors.neutral,
              ),
              const SizedBox(width: 4),
              Text(
                'Back to today',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CupertinoColors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? AppColors.primaryInk
                : AppColors.primaryInk.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}

class _KmTotal extends StatelessWidget {
  final double km;
  const _KmTotal({required this.km});

  @override
  Widget build(BuildContext context) {
    final label = km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _goldAccent,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'KM TOTAL',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: _labelMuted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day tile
// ---------------------------------------------------------------------------

class _DayTile extends StatelessWidget {
  final TrainingDay day;
  final _DayHighlight highlight;
  final VoidCallback onTap;
  const _DayTile({
    required this.day,
    required this.highlight,
    required this.onTap,
  });

  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  DateTime? get _date => DateTime.tryParse(day.date);

  TrainingDayStatus get _status => TrainingDayStatus.from(day);

  bool get _isCompleted => _status == TrainingDayStatus.completed;

  bool get _isMissed => _status == TrainingDayStatus.missed;

  /// `true` when this tile gets the gold halo (today / next-upcoming).
  /// Completed gets its own GREEN halo via `_isCompleted`; missed never glows.
  bool get _isGoldHaloed => !_isCompleted && highlight != _DayHighlight.none;

  /// Any glow at all? Drives the elevated card shadow + radial gradient.
  bool get _isHaloed => _isCompleted || _isGoldHaloed;

  String? get _badgeLabel {
    if (_isCompleted) return 'DONE';
    if (_isMissed) return 'MISSED';
    return switch (highlight) {
      _DayHighlight.today => 'TODAY',
      _DayHighlight.upcoming => 'UPCOMING',
      _DayHighlight.none => null,
    };
  }

  Color? get _badgeColor {
    if (_isCompleted) return AppColors.success;
    if (_isMissed) return AppColors.danger;
    return null; // null = default gold from GoldBadge
  }

  String get _subtitle {
    final pace = day.targetPaceSecondsPerKm;
    if (pace != null && pace > 0) {
      final m = pace ~/ 60;
      final s = (pace % 60).toString().padLeft(2, '0');
      return 'Target: $m:$s min/km';
    }
    return day.description ?? '';
  }

  /// Title with the target distance prepended when available, e.g.
  /// `"5km Easy run"`. Falls back to the raw title for interval/mobility days
  /// where a single target distance doesn't make sense.
  String get _displayTitle {
    final km = day.targetKm;
    if (km == null || km <= 0) return day.title;
    final label = km == km.truncate()
        ? '${km.toInt()}km'
        : '${km.toStringAsFixed(1)}km';
    return '$label ${day.title}';
  }

  @override
  Widget build(BuildContext context) {
    final haloed = _isHaloed;
    final isCompleted = _isCompleted;
    final badgeLabel = _badgeLabel;
    final badgeColor = _badgeColor;

    // Halo accent: green for completed, gold for today / next-upcoming.
    // Same intensity in both colors so the visual treatment matches.
    final accent = isCompleted ? AppColors.success : AppColors.secondary;
    final shadowOuter = isCompleted ? const Color(0x6634C759) : const Color(0x73E9B638);
    final shadowInner = isCompleted ? const Color(0x3334C759) : const Color(0x38E9B638);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: haloed
            ? [
                BoxShadow(
                  color: shadowOuter,
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: shadowInner,
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x0A37280F),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Material(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: haloed
                  ? RadialGradient(
                      center: Alignment.centerRight,
                      radius: 3.5,
                      colors: [
                        accent.withValues(alpha: 0.15),
                        accent.withValues(alpha: 0.0),
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: _DayStamp(date: _date, highlighted: haloed),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (badgeLabel != null) ...[
                            GoldBadge(label: badgeLabel, color: badgeColor),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              _displayTitle,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryInk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _goldAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusIcon(status: _status, isHaloed: haloed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayStamp extends StatelessWidget {
  final DateTime? date;
  final bool highlighted;
  const _DayStamp({required this.date, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final d = date;
    final dayLabel = d == null ? '' : _DayTile._dayNames[d.weekday - 1];
    final dayNumber = d == null ? '' : '${d.day}';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          dayLabel,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: highlighted ? _goldAccent : _labelMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dayNumber,
          style: GoogleFonts.spaceGrotesk(
            fontSize: highlighted ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryInk,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final TrainingDayStatus status;
  final bool isHaloed;
  const _StatusIcon({required this.status, required this.isHaloed});

  static const _size = 32.0;
  static const _pendingBg = Color(0xFFF1EAD8);
  static const _pendingIcon = Color(0xFFB0A590);

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      TrainingDayStatus.completed => const _CircleIcon(
        bg: AppColors.success,
        icon: Icons.check_rounded,
        iconColor: CupertinoColors.white,
        iconSize: 18,
      ),
      TrainingDayStatus.missed => const _CircleIcon(
        bg: AppColors.danger,
        icon: Icons.close_rounded,
        iconColor: CupertinoColors.white,
        iconSize: 18,
      ),
      TrainingDayStatus.today => const _CircleIcon(
        bg: AppColors.secondary,
        icon: Icons.bolt_rounded,
        iconColor: CupertinoColors.white,
        iconSize: 18,
      ),
      TrainingDayStatus.upcoming => isHaloed
          ? const _CircleIcon(
              bg: AppColors.secondary,
              icon: Icons.bolt_rounded,
              iconColor: CupertinoColors.white,
              iconSize: 18,
            )
          : const _CircleIcon(
              bg: _pendingBg,
              icon: Icons.schedule_rounded,
              iconColor: _pendingIcon,
              iconSize: 16,
            ),
    };
  }
}

class _CircleIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  const _CircleIcon({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _StatusIcon._size,
      height: _StatusIcon._size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}
