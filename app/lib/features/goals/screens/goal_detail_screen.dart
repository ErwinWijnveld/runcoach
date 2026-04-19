import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, InkWell, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/goals/data/goal_coach_suggestions.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/providers/goal_provider.dart';

class GoalDetailScreen extends ConsumerWidget {
  final int goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalDetailProvider(goalId));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: goalAsync.when(
        loading: () => const SafeArea(child: AppSpinner()),
        error: (err, _) => SafeArea(child: AppErrorState(title: 'Error: $err')),
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
    final response = await api.createConversation({'title': 'New Chat'});
    final id = response['data']['id'];
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.go('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = goal.status == 'active';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BackButton(),
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
                  const _SectionTitle('Training'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _ScheduleRow(
                      onTap: () => context.go('/schedule'),
                    ),
                  ),
                ] else if (goal.status == 'paused' ||
                    goal.status == 'planning') ...[
                  const _SectionTitle('Not active'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _SwitchToGoalCard(goal: goal),
                  ),
                ],
                const SizedBox(height: 20),
                if (goal.status == 'active' ||
                    goal.status == 'paused' ||
                    goal.status == 'planning') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: AppFilledButton(
                      label: 'Delete goal',
                      icon: CupertinoIcons.delete,
                      color: AppColors.danger,
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CoachPromptBar.navigateAnimated(
                onTap: () => _startNewChat(context, ref),
                animatedSuggestions: goalCoachSuggestions,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete goal',
      message: 'Are you sure you want to delete "${goal.name}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'No',
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
                      Text(
                        goal.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primaryInk,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(goal),
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

String _subtitle(Goal goal) {
  final days = _daysUntil(goal);
  if (days != null && days >= 0) {
    return days == 0 ? 'RACE DAY' : '$days DAYS TO GO';
  }
  return [
    if (goal.distance != null) goal.distance!.toUpperCase(),
    if (goal.targetDate != null) goal.targetDate!,
  ].join(' · ');
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
    final days = _daysUntil(goal);
    final daysStr = days == null
        ? (goal.targetDate ?? '-')
        : (days < 0 ? 'PAST' : (days == 0 ? 'TODAY' : '$days'));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Tile(label: 'DISTANCE', value: goal.distance ?? '-'),
        ),
        const SizedBox(width: 8),
        Expanded(child: _Tile(label: 'GOAL TIME', value: _formatGoalTime())),
        const SizedBox(width: 8),
        Expanded(
          child: _Tile(
            label: days == null || days < 0 ? 'TARGET' : 'DAYS LEFT',
            value: daysStr,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        child: Column(
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back button (same visual as schedule day detail)
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.canPop() ? context.pop() : context.go('/goals'),
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
  const _ScheduleRow({required this.onTap});

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
                    'Training schedule',
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                  Text(
                    'Open your weekly plan',
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
            'Switch to this goal',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your current active goal will be paused.',
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
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
