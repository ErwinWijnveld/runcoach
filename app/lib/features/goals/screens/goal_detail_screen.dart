import 'dart:ui';

import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/core/widgets/runboost_logo.dart';
import 'package:app/core/widgets/intro_fx.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/goals/data/goal_coach_suggestions.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/providers/goal_provider.dart';
import 'package:app/features/goals/widgets/goal_plan_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  final int goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalDetailProvider(goalId));

    return GradientScaffold(
      child: goalAsync.when(
        loading: () => const SafeArea(child: AppSpinner()),
        error: (err, _) => SafeArea(child: AppErrorState(title: context.l10n.commonErrorWithMessage(err.toString()))),
        data: (goal) => _Loaded(goal: goal),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  final Goal goal;
  const _Loaded({required this.goal});

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final api = ref.read(coachApiProvider);
    final response = await api.createConversation({
      'title': context.l10n.newChatTitle,
    });
    final id = response['data']['id'];
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.go('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = goal.status == 'active';

    final canDelete = goal.status == 'active' ||
        goal.status == 'paused' ||
        goal.status == 'planning';

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            showMore: canDelete,
            onMore: () => _showMoreActions(context, ref),
          ),
          Expanded(
            child: IntroFx(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: _GoalHeroCard(goal: goal),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: _GoalStatTiles(goal: goal),
                          ),
                          const SizedBox(height: 16),
                          if (isActive) ...[
                            _SectionTitle(context.l10n.goalDetailSectionTraining),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _ScheduleRow(
                                onTap: () =>
                                    GoalPlanSheet.show(context, goal: goal),
                              ),
                            ),
                          ] else if (goal.status == 'paused' ||
                              goal.status == 'planning') ...[
                            _SectionTitle(context.l10n.goalDetailSectionNotActive),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _ScheduleRow(
                                subtitle: context.l10n.goalsScheduleRowSubtitlePreview,
                                onTap: () =>
                                    GoalPlanSheet.show(context, goal: goal),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _SwitchToGoalCard(goal: goal),
                            ),
                          ],
                          const Spacer(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CoachPromptBar.navigateAnimated(
                onTap: () => _startNewChat(context, ref),
                animatedSuggestions: goalCoachSuggestions(context.l10n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreActions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              _confirmDelete(context, ref);
            },
            child: Text(context.l10n.goalsDeleteGoal),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: Text(context.l10n.commonCancel),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirm(
      context,
      title: l10n.goalsDeleteGoal,
      message: l10n.goalsDeleteConfirmBody(goal.name),
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonNo,
      destructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(goalActionsProvider.notifier).deleteGoal(goal.id);
      if (context.mounted) context.go('/goals');
    }
  }
}

// ---------------------------------------------------------------------------
// Hero — mirrors TrainingDayHeroCard (background + frosted slab)
// ---------------------------------------------------------------------------

class _GoalHeroCard extends StatelessWidget {
  final Goal goal;
  const _GoalHeroCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.goldGlow,
                  boxShadow: [
                    BoxShadow(color: Color(0x0D000000), blurRadius: 16),
                  ],
                ),
                child: Image.asset(
                  'assets/images/finisher.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusPillColor(goal.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          goal.status.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RunBoostHeading(
                        goal.name,
                        size: 30,
                        height: 1.05,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(context, goal),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _statusPillColor(goal.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusPillColor(String status) => switch (status) {
  'active' => AppColors.secondary,
  'completed' => AppColors.success,
  'paused' => AppColors.inkMuted,
  'planning' => AppColors.gold,
  _ => AppColors.inkMuted,
};

String _subtitle(BuildContext context, Goal goal) {
  final l10n = context.l10n;
  final days = _daysUntil(goal);
  if (days != null && days >= 0) {
    return days == 0 ? l10n.goalsCardRaceDay : l10n.goalsCardDaysToGo(days);
  }
  return [
    if (goal.distance != null) goal.distance!.toUpperCase(),
    if (goal.targetDate != null) formatDateString(goal.targetDate),
  ].where((s) => s.isNotEmpty).join(' · ');
}

int? _daysUntil(Goal goal) {
  final td = goal.targetDate;
  if (td == null) return null;
  try {
    final d = DateTime.parse(td);
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// 3 stat tiles row (mirrors TrainingDayStatTiles)
// ---------------------------------------------------------------------------

class _GoalStatTiles extends StatelessWidget {
  final Goal goal;
  const _GoalStatTiles({required this.goal});

  String _formatGoalTime() {
    final s = goal.goalTimeSeconds;
    if (s == null) return '-';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = _daysUntil(goal);
    final daysStr = days == null
        ? formatDateString(goal.targetDate, fallback: '-')
        : (days < 0 ? l10n.goalsCardPast : (days == 0 ? l10n.commonTodayUpper : '$days'));

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _Cell(label: l10n.goalsCardDistance, value: goal.distance ?? '-'),
            ),
            const _CellDivider(),
            Expanded(
              child: _Cell(label: l10n.goalsCardGoalTime, value: _formatGoalTime()),
            ),
            const _CellDivider(),
            Expanded(
              child: _Cell(
                label: days == null || days < 0 ? l10n.goalsCardTarget : l10n.goalsCardDaysLeft,
                value: daysStr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Text(
          value,
          style: RunCoreText.statValue(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.lightTan,
    );
  }
}

// ---------------------------------------------------------------------------
// Back button (same visual as schedule day detail)
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final bool showMore;
  final VoidCallback onMore;
  const _TopBar({required this.showMore, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/goals'),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  CupertinoIcons.back,
                  color: AppColors.primaryInk,
                  size: 22,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (showMore)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onMore,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    CupertinoIcons.ellipsis_circle,
                    color: AppColors.primaryInk,
                    size: 24,
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
// Section title + navigation-style rows
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final VoidCallback onTap;
  final String? subtitle;
  const _ScheduleRow({required this.onTap, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: AppColors.warmBrown,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.goalsScheduleRowTitle,
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                  Text(
                    subtitle ?? context.l10n.goalsScheduleRowSubtitle,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchToGoalCard extends ConsumerWidget {
  final Goal goal;
  const _SwitchToGoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.goalsSwitchToThis,
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.goalsSwitchToThisBody,
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            onPressed: () async {
              await ref
                  .read(goalActionsProvider.notifier)
                  .activateGoal(goal.id);
            },
            child: Text(context.l10n.goalsCardSwitch),
          ),
        ],
      ),
    );
  }
}
