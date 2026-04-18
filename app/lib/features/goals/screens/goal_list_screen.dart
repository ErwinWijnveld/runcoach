import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/providers/goal_provider.dart';

const List<_GoalSuggestion> _suggestions = [
  _GoalSuggestion('Train for a marathon'),
  _GoalSuggestion('Get faster at 10k'),
  _GoalSuggestion('Improve general fitness'),
  _GoalSuggestion('I have a race coming up'),
];

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverNavigationBar(
                    backgroundColor: AppColors.cream.withValues(alpha: 0.92),
                    border: null,
                    largeTitle: const Text('Goals'),
                  ),
                  CupertinoSliverRefreshControl(
                    onRefresh: () async => ref.invalidate(goalsProvider),
                  ),
                  goalsAsync.when(
                    loading: () =>
                        const SliverFillRemaining(child: AppSpinner()),
                    error: (_, _) => SliverFillRemaining(
                      child: AppErrorState(
                        title: 'Could not load goals',
                        onRetry: () => ref.invalidate(goalsProvider),
                      ),
                    ),
                    data: (goals) => _GoalsBody(goals: goals),
                  ),
                ],
              ),
            ),
            const _CoachEntryBar(),
          ],
        ),
      ),
    );
  }
}

class _GoalsBody extends StatelessWidget {
  final List<Goal> goals;
  const _GoalsBody({required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(),
      );
    }

    // Active first, then everything else by most-recent target_date.
    final active = goals.where((g) => g.status == 'active').toList();
    final others = goals.where((g) => g.status != 'active').toList();
    final ordered = [...active, ...others];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverList.separated(
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _GoalRow(goal: ordered[i]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.flag,
              size: 56,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No goals yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ask the coach below to build your first training plan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends ConsumerWidget {
  final Goal goal;
  const _GoalRow({required this.goal});

  bool get _isActive => goal.status == 'active';

  int? _daysUntil() {
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

  String _trailingLabel() {
    final days = _daysUntil();
    if (_isActive && days != null && days >= 0) {
      return days == 0 ? 'Race day' : '${days}d';
    }
    return goal.status;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isActive) {
          context.go('/goals/${goal.id}');
        } else {
          _showSwitchSheet(context, ref);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _isActive ? AppColors.cardBg : AppColors.lightTan,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isActive
                ? AppColors.warmBrown.withValues(alpha: 0.35)
                : AppColors.border,
            width: _isActive ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (goal.distance != null) goal.distance,
                      if (goal.targetDate != null) goal.targetDate,
                    ].whereType<String>().join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _trailingLabel(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isActive
                    ? AppColors.warmBrown
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Switch active goal?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Make "${goal.name}" your active goal. Your current active goal will be paused.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  await ref
                      .read(goalActionsProvider.notifier)
                      .activateGoal(goal.id);
                },
                child: const Text('Switch'),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachEntryBar extends ConsumerWidget {
  const _CoachEntryBar();

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final api = ref.read(coachApiProvider);
    final response = await api.createConversation({'title': 'New Chat'});
    final id = response['data']['id'];
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.go('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in _suggestions) ...[
                  _SuggestionChip(
                    label: s.label,
                    onTap: () => _startNewChat(context, ref),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _startNewChat(context, ref),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ask the coach anything…',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 22,
                    color: AppColors.warmBrown,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _GoalSuggestion {
  final String label;
  const _GoalSuggestion(this.label);
}
