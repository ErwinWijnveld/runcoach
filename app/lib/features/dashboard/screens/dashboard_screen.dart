import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, InkWell;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_header.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/wearable/widgets/analyzing_run_chip.dart';
import 'package:app/router/app_router.dart'
    show floatingPromptBarBottomOffset, kBottomStackedReservedHeight;

// ---------------------------------------------------------------------------
// Local palette — matches the RunBoost M2 mockup while leaning on AppColors
// where the tokens align (cream, gold, muted ink). Kept local to this file
// because these greys and beiges are used only by the matrix / bar chart.
// ---------------------------------------------------------------------------

const _eyebrowGold = Color(0xFFB8871A);
const _muted = Color(0xFF7A6A4E);
const _muted2 = Color(0xFFA79274);
const _inkBlack = Color(0xFF1A1510);
const _restCell = Color(0xFFEFE7D2);
const _lineSoft = Color(0x2E7A6A4E);

const int _weeksPerPage = 16;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
                const AnalyzingRunChip(),
                Expanded(
                  child: dashboardAsync.when(
                    loading: () => const AppSpinner(),
                    error: (err, _) => AppErrorState(
                      title: 'Error: $err',
                      onRetry: () => ref.invalidate(dashboardProvider),
                    ),
                    data: (dashboard) {
                      final goal = dashboard.activeGoal;
                      if (goal == null) {
                        return _EmptyState(
                          onOpenGoals: () => context.go('/goals'),
                        );
                      }
                      final weeksAsync = ref.watch(
                        scheduleProvider(goal.id),
                      );
                      return weeksAsync.when(
                        loading: () => const AppSpinner(),
                        error: (err, _) => AppErrorState(
                          title: 'Error: $err',
                          onRetry: () =>
                              ref.invalidate(scheduleProvider(goal.id)),
                        ),
                        data: (weeks) {
                          if (weeks.isEmpty) {
                            return _EmptyState(
                              onOpenGoals: () => context.go('/goals'),
                            );
                          }
                          return _DashboardContent(
                            dashboard: dashboard,
                            goal: goal,
                            weeks: weeks,
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
                child: CoachPromptBar.navigate(
                  onTap: () => startNewCoachChat(context, ref),
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
// Content: three cards
// ---------------------------------------------------------------------------

class _DashboardContent extends StatelessWidget {
  final DashboardData dashboard;
  final ActiveGoalSummary goal;
  final List<TrainingWeek> weeks;

  const _DashboardContent({
    required this.dashboard,
    required this.goal,
    required this.weeks,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final raceDate = _tryParseDate(goal.targetDate);

    final selectedDay = _selectTodayOrUpcoming(weeks, today);
    final currentWeek = _findCurrentWeek(weeks, today);
    final daysToGo = raceDate?.difference(today).inDays;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        kBottomStackedReservedHeight,
      ),
      child: IntroColumn(
        spacing: 12,
        children: [
          _TodayCard(
            day: selectedDay,
            today: today,
            raceDate: raceDate,
            onTap: () => selectedDay == null
                ? context.go('/schedule')
                : context.go('/schedule/day/${selectedDay.id}'),
          ),
          _ThisWeekCard(
            week: currentWeek,
            today: today,
            summary: dashboard.weeklySummary,
            raceDate: raceDate,
            onTap: () => context.go('/schedule'),
          ),
          _WeeksMatrixCard(
            weeks: weeks,
            today: today,
            raceDate: raceDate,
            raceName: goal.name,
            daysToGo: daysToGo,
            onTap: () => context.go('/schedule'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today card — shows today's run if one is planned & not yet done,
// otherwise the next upcoming run.
// ---------------------------------------------------------------------------

class _TodayCard extends StatelessWidget {
  final TrainingDay? day;
  final DateTime today;
  final DateTime? raceDate;
  final VoidCallback onTap;

  const _TodayCard({
    required this.day,
    required this.today,
    required this.raceDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    return _RoundedCard(
      onTap: onTap,
      child: day == null
          ? _buildEmpty()
          : _buildContent(day),
    );
  }

  Widget _buildEmpty() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NO UPCOMING RUN',
                style: RunCoreText.sectionEyebrow(color: _eyebrowGold),
              ),
              const SizedBox(height: 6),
              Text(
                'Plan complete',
                style: RunCoreText.serifTitle(size: 26, height: 30 / 26),
              ),
              const SizedBox(height: 4),
              Text(
                'All training days are logged.',
                style: RunCoreText.statSuffix(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleIconButton(
          icon: Icons.arrow_forward,
          size: 46,
          iconSize: 20,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildContent(TrainingDay day) {
    final date = DateTime.parse(day.date);
    final dayLabel = _relativeDayLabel(date, today).toUpperCase();

    final distance = day.targetKm == null
        ? null
        : '${_trimDecimal(day.targetKm!)} km';
    final pace = day.targetPaceSecondsPerKm == null
        ? null
        : '${_formatPace(day.targetPaceSecondsPerKm!)} min/km';
    final duration = _estimatedDuration(
      day.targetKm,
      day.targetPaceSecondsPerKm,
    );

    final detail = <String>[
      ?distance,
      ?pace,
      ?duration,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldGlow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dayLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.eyebrow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.title,
                    style: RunCoreText.serifTitle(size: 26, height: 30 / 26),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleIconButton(
              icon: Icons.arrow_forward,
              size: 46,
              iconSize: 20,
              onTap: onTap,
            ),
          ],
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(detail, style: RunCoreText.statSuffix(color: _muted)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// This week card — 7-day bar chart (Mon..Sun)
// ---------------------------------------------------------------------------

class _ThisWeekCard extends StatelessWidget {
  final TrainingWeek? week;
  final DateTime today;
  final WeeklySummary? summary;
  final DateTime? raceDate;
  final VoidCallback onTap;

  const _ThisWeekCard({
    required this.week,
    required this.today,
    required this.summary,
    required this.raceDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final week = this.week;
    final cells = week == null
        ? List<_DayCell>.filled(7, const _DayCell(state: _CellState.rest))
        : _buildWeekCells(week, today, raceDate);

    final maxKm = cells
        .map((c) => c.targetKm ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    final completed = summary?.totalKmCompleted ?? 0;
    final planned = summary?.totalKmPlanned ??
        cells.fold<double>(0, (a, c) => a + (c.targetKm ?? 0));

    return _RoundedCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'THIS WEEK',
                  style: RunCoreText.sectionEyebrow(color: _muted),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: RunCoreText.statSuffix(color: _muted),
                  children: [
                    TextSpan(
                      text: _trimDecimal(completed),
                      style: RunCoreText.statValue(
                        color: AppColors.primaryInk,
                        size: 16,
                      ),
                    ),
                    TextSpan(text: ' / ${_trimDecimal(planned)} km'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeekBars(cells: cells, maxKm: maxKm == 0 ? 1 : maxKm),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  final List<_DayCell> cells;
  final double maxKm;
  const _WeekBars({required this.cells, required this.maxKm});

  @override
  Widget build(BuildContext context) {
    const height = 62.0;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final cell = cells[i];
        final km = cell.targetKm ?? 0;
        final ratio = maxKm == 0 ? 0.0 : (km / maxKm).clamp(0.0, 1.0);
        final barHeight = km == 0 ? 4.0 : 6.0 + ratio * (height - 6.0);
        final color = _barColor(cell);
        final label = dayLabels[i];
        final isToday = cell.isToday;
        final dayLabel = Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isToday ? CupertinoColors.white : _muted,
          ),
        );
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (isToday)
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: dayLabel,
                  )
                else
                  dayLabel,
              ],
            ),
          ),
        );
      }),
    );
  }
}

Color _barColor(_DayCell cell) {
  switch (cell.state) {
    case _CellState.rest:
      return _restCell;
    case _CellState.done:
      return AppColors.success;
    case _CellState.missed:
      return AppColors.danger;
    case _CellState.race:
      return _inkBlack;
    case _CellState.upcoming:
      return AppColors.secondary;
  }
}

// ---------------------------------------------------------------------------
// N-weeks matrix card with pagination
// ---------------------------------------------------------------------------

class _WeeksMatrixCard extends StatefulWidget {
  final List<TrainingWeek> weeks;
  final DateTime today;
  final DateTime? raceDate;
  final String raceName;
  final int? daysToGo;
  final VoidCallback onTap;

  const _WeeksMatrixCard({
    required this.weeks,
    required this.today,
    required this.raceDate,
    required this.raceName,
    required this.daysToGo,
    required this.onTap,
  });

  @override
  State<_WeeksMatrixCard> createState() => _WeeksMatrixCardState();
}

class _WeeksMatrixCardState extends State<_WeeksMatrixCard> {
  late final PageController _controller;
  late int _pageIndex;

  int get _pageCount =>
      (widget.weeks.length / _weeksPerPage).ceil().clamp(1, 999);

  int _initialPageFor(int currentWeekIdx) =>
      (currentWeekIdx / _weeksPerPage).floor().clamp(0, _pageCount - 1);

  int? _currentWeekIndex() {
    for (int i = 0; i < widget.weeks.length; i++) {
      final start = DateTime.tryParse(widget.weeks[i].startsAt);
      if (start == null) continue;
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = startDate.add(const Duration(days: 6));
      if (!widget.today.isBefore(startDate) &&
          !widget.today.isAfter(endDate)) {
        return i;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final currentWeekIdx = _currentWeekIndex() ?? 0;
    _pageIndex = _initialPageFor(currentWeekIdx);
    _controller = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.weeks.length;
    final daysToGo = widget.daysToGo;
    final rightLabel = (daysToGo == null || daysToGo < 0)
        ? widget.raceName
        : daysToGo == 0
            ? 'Race day · ${widget.raceName}'
            : '${daysToGo}d · ${widget.raceName}';

    return _RoundedCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '$total WEEKS',
                  style: RunCoreText.sectionEyebrow(color: _eyebrowGold),
                ),
              ),
              Flexible(
                child: Text(
                  rightLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Geometry is derived from a hypothetical 16-week row, so that
              // short plans use the SAME compact cell size (grid just ends
              // sooner, rest of the card stays empty). Matches the target
              // mockup where cells are always ~15-16px, never bigger.
              const labelColWidth = 13.0;
              const gapAfterLabels = 8.0;
              const colGap = 3.0;
              const rowGap = 2.0;

              final gridWidth = (constraints.maxWidth -
                      labelColWidth -
                      gapAfterLabels)
                  .clamp(0.0, double.infinity);
              final cellSize = ((gridWidth -
                          (_weeksPerPage - 1) * colGap) /
                      _weeksPerPage)
                  .clamp(8.0, 18.0);
              final gridHeight = cellSize * 7 + rowGap * 6;
              final singlePage = _pageCount == 1;

              if (singlePage) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MatrixPage(
                      weeks: widget.weeks,
                      today: widget.today,
                      raceDate: widget.raceDate,
                      cellSize: cellSize,
                      slotCount: widget.weeks.length,
                    ),
                    const SizedBox(height: 12),
                    const _Legend(),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: gridHeight,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pageCount,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, p) {
                        final start = p * _weeksPerPage;
                        final end = (start + _weeksPerPage)
                            .clamp(0, widget.weeks.length);
                        return _MatrixPage(
                          weeks: widget.weeks.sublist(start, end),
                          today: widget.today,
                          raceDate: widget.raceDate,
                          cellSize: cellSize,
                          slotCount: _weeksPerPage,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _PageDots(
                      count: _pageCount,
                      active: _pageIndex,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _Legend(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MatrixPage extends StatelessWidget {
  final List<TrainingWeek> weeks;
  final DateTime today;
  final DateTime? raceDate;

  /// Total column slots to render (always equals the actual week count for
  /// single-page matrices, or `_weeksPerPage` for paginated pages so cell
  /// size stays consistent across pages).
  final int slotCount;

  /// Explicit cell width/height, computed by the parent via LayoutBuilder.
  final double cellSize;

  const _MatrixPage({
    required this.weeks,
    required this.today,
    required this.raceDate,
    required this.cellSize,
    required this.slotCount,
  });

  @override
  Widget build(BuildContext context) {
    final columns = weeks.map((w) {
      final cells = _buildWeekCells(w, today, raceDate);
      return _WeekColumn(cells: cells);
    }).toList();

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const rowGap = 2.0;
    const colGap = 3.0;
    final gridHeight = cellSize * 7 + rowGap * 6;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 13,
          height: gridHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in dayLabels)
                SizedBox(
                  height: cellSize,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: _muted2,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(slotCount, (i) {
            final hasWeek = i < columns.length;
            return Padding(
              padding: EdgeInsets.only(right: i == slotCount - 1 ? 0 : colGap),
              child: SizedBox(
                width: cellSize,
                child: hasWeek
                    ? _MatrixColumn(
                        column: columns[i],
                        cellSize: cellSize,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WeekColumn {
  final List<_DayCell> cells;
  const _WeekColumn({required this.cells});
}

class _MatrixColumn extends StatelessWidget {
  final _WeekColumn column;
  final double cellSize;

  const _MatrixColumn({
    required this.column,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int d = 0; d < 7; d++) ...[
          SizedBox(
            height: cellSize,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _cellColor(column.cells[d]),
                borderRadius: BorderRadius.circular(2),
                border: column.cells[d].isToday
                    ? Border.all(color: AppColors.secondary, width: 1.5)
                    : null,
              ),
              child: column.cells[d].state == _CellState.race
                  ? const Center(
                      child: Icon(
                        Icons.star,
                        size: 8,
                        color: Color(0xFFFFE8A6),
                      ),
                    )
                  : null,
            ),
          ),
          if (d < 6) const SizedBox(height: 2),
        ],
      ],
    );
  }
}

Color _cellColor(_DayCell cell) {
  switch (cell.state) {
    case _CellState.rest:
      return _restCell;
    case _CellState.done:
      return AppColors.success;
    case _CellState.missed:
      return AppColors.danger;
    case _CellState.upcoming:
      return AppColors.secondary;
    case _CellState.race:
      return _inkBlack;
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _PageDots extends StatelessWidget {
  final int count;
  final int active;
  const _PageDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : _lineSoft,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendDot(color: AppColors.success, label: 'Done'),
        _LegendDot(color: AppColors.danger, label: 'Missed'),
        _LegendDot(color: AppColors.secondary, label: 'Upcoming'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ],
    );
  }
}

class _RoundedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const _RoundedCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A37280F),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: card),
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
              CupertinoIcons.flag,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No active plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick a goal (or ask the coach to build one) to see '
              'your training on the dashboard.',
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
// Model + derivation helpers
// ---------------------------------------------------------------------------

enum _CellState { rest, done, missed, upcoming, race }

class _DayCell {
  final _CellState state;
  final bool isToday;
  final double? targetKm;
  final String? type;
  final TrainingDay? day;

  const _DayCell({
    required this.state,
    this.isToday = false,
    this.targetKm,
    this.type,
    this.day,
  });
}

/// Build 7 cells (Mon..Sun) for a training week, filling weekdays without
/// a scheduled day as `rest`.
List<_DayCell> _buildWeekCells(
  TrainingWeek week,
  DateTime today,
  DateTime? raceDate,
) {
  final cells = List<_DayCell>.filled(
    7,
    const _DayCell(state: _CellState.rest),
  );

  for (final day in week.trainingDays ?? const <TrainingDay>[]) {
    final date = DateTime.tryParse(day.date);
    if (date == null) continue;
    final weekday = date.weekday - 1; // Mon=0..Sun=6
    if (weekday < 0 || weekday > 6) continue;
    final dateOnly = DateTime(date.year, date.month, date.day);
    cells[weekday] = _DayCell(
      state: _deriveState(day, today, raceDate),
      isToday: _sameDay(dateOnly, today),
      targetKm: day.targetKm,
      type: day.type,
      day: day,
    );
  }

  // Mark today's slot even if it's a rest day (no TrainingDay for that date),
  // but only when `today` falls within this week's range.
  final weekStart = DateTime.tryParse(week.startsAt);
  if (weekStart != null) {
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndDay = weekStartDay.add(const Duration(days: 6));
    if (!today.isBefore(weekStartDay) && !today.isAfter(weekEndDay)) {
      final idx = today.weekday - 1;
      if (idx >= 0 && idx < 7 && !cells[idx].isToday) {
        cells[idx] = _DayCell(
          state: cells[idx].state,
          isToday: true,
          targetKm: cells[idx].targetKm,
          type: cells[idx].type,
          day: cells[idx].day,
        );
      }
    }
  }

  return cells;
}

_CellState _deriveState(TrainingDay day, DateTime today, DateTime? raceDate) {
  final date = DateTime.tryParse(day.date);
  if (date == null) return _CellState.rest;
  final dateOnly = DateTime(date.year, date.month, date.day);
  if (raceDate != null && _sameDay(dateOnly, raceDate)) {
    return _CellState.race;
  }
  if (day.result != null) return _CellState.done;
  if (dateOnly.isBefore(today)) return _CellState.missed;
  return _CellState.upcoming;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

TrainingDay? _selectTodayOrUpcoming(
  List<TrainingWeek> weeks,
  DateTime today,
) {
  final allDays = weeks
      .expand((w) => w.trainingDays ?? const <TrainingDay>[])
      .toList();
  TrainingDay? todayDay;
  TrainingDay? upcoming;
  DateTime? bestUpcomingDate;

  for (final day in allDays) {
    final parsed = DateTime.tryParse(day.date);
    if (parsed == null) continue;
    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    if (_sameDay(dateOnly, today) && day.result == null) {
      todayDay = day;
      break;
    }
    if (dateOnly.isAfter(today) && day.result == null) {
      if (bestUpcomingDate == null || dateOnly.isBefore(bestUpcomingDate)) {
        bestUpcomingDate = dateOnly;
        upcoming = day;
      }
    }
  }

  return todayDay ?? upcoming;
}

TrainingWeek? _findCurrentWeek(List<TrainingWeek> weeks, DateTime today) {
  for (final week in weeks) {
    final start = DateTime.tryParse(week.startsAt);
    if (start == null) continue;
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = startDate.add(const Duration(days: 6));
    if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
      return week;
    }
  }
  // Fallback: earliest future week, or the last week if everything is past.
  TrainingWeek? nextFuture;
  DateTime? nextFutureDate;
  TrainingWeek? latestPast;
  DateTime? latestPastDate;
  for (final week in weeks) {
    final start = DateTime.tryParse(week.startsAt);
    if (start == null) continue;
    final startDate = DateTime(start.year, start.month, start.day);
    if (startDate.isAfter(today)) {
      if (nextFutureDate == null || startDate.isBefore(nextFutureDate)) {
        nextFutureDate = startDate;
        nextFuture = week;
      }
    } else {
      if (latestPastDate == null || startDate.isAfter(latestPastDate)) {
        latestPastDate = startDate;
        latestPast = week;
      }
    }
  }
  return nextFuture ?? latestPast;
}

DateTime? _tryParseDate(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  return DateTime(dt.year, dt.month, dt.day);
}

String _relativeDayLabel(DateTime date, DateTime today) {
  final d = DateTime(date.year, date.month, date.day);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff > 1 && diff < 7) return DateFormat.EEEE().format(d);
  if (diff < 0) return DateFormat.EEEE().format(d);
  return DateFormat('MMM d').format(d);
}

String _trimDecimal(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatPace(int secondsPerKm) {
  final m = secondsPerKm ~/ 60;
  final s = secondsPerKm % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String? _estimatedDuration(double? km, int? paceSecPerKm) {
  if (km == null || paceSecPerKm == null) return null;
  final total = (km * paceSecPerKm).round();
  if (total < 60) return '$total s';
  final minutes = (total / 60).round();
  return '$minutes min';
}
