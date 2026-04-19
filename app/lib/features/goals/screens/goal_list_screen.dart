import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show RoundedRectangleBorder, showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_header.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/coach_prompt_bar.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/goals/data/goal_coach_suggestions.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/providers/goal_provider.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final api = ref.read(coachApiProvider);
    final response = await api.createConversation({'title': 'New Chat'});
    final id = response['data']['id'];
    ref.invalidate(conversationsProvider);
    if (context.mounted) context.go('/coach/chat/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: goalsAsync.when(
                loading: () => const AppSpinner(),
                error: (err, _) => AppErrorState(
                  title: 'Error: $err',
                  onRetry: () => ref.invalidate(goalsProvider),
                ),
                data: (goals) => _GoalsBody(goals: goals),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: CoachPromptBar.navigateAnimated(
                  onTap: () => _startNewChat(context, ref),
                  animatedSuggestions: goalCoachSuggestions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _GoalsBody extends StatelessWidget {
  final List<Goal> goals;
  const _GoalsBody({required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const _EmptyState();
    }

    final active = goals.where((g) => g.status == 'active').toList();
    final others = goals.where((g) => g.status != 'active').toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _GoalsHeader(),
          ),
          if (active.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _ActiveGoalCard(goal: active.first),
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SectionTitle('Other goals'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  for (int i = 0; i < others.length; i++) ...[
                    _OtherGoalTile(goal: others[i]),
                    if (i < others.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Your goals',
          style: GoogleFonts.ebGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: AppColors.primaryInk,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.inkMuted,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active goal — large feature card (matches hero slabs elsewhere in the app)
// ---------------------------------------------------------------------------

class _ActiveGoalCard extends StatelessWidget {
  final Goal goal;
  const _ActiveGoalCard({required this.goal});

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

  String _formatGoalTime() {
    final s = goal.goalTimeSeconds;
    if (s == null) return '-';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go('/goals/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [GoldBadge(label: 'ACTIVE')]),
            const SizedBox(height: 8),
            Text(
              goal.name,
              style: GoogleFonts.ebGaramond(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryInk,
                height: 1.05,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatMini(
                    label: 'DISTANCE',
                    value: goal.distance ?? '-',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMini(label: 'GOAL TIME', value: _formatGoalTime()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatMini(
                    label: days == null || days < 0
                        ? 'TARGET'
                        : (days == 0 ? 'TODAY' : 'DAYS LEFT'),
                    value: days == null || days < 0
                        ? (goal.targetDate ?? '-')
                        : (days == 0 ? '🏁' : '$days'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: RunCoreText.statLabel()),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inactive / past goal row
// ---------------------------------------------------------------------------

class _OtherGoalTile extends ConsumerWidget {
  final Goal goal;
  const _OtherGoalTile({required this.goal});

  bool get _canReactivate =>
      goal.status == 'paused' || goal.status == 'planning';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_canReactivate) {
          _showSwitchSheet(context, ref);
        } else {
          context.go('/goals/${goal.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 10),
          ],
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
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (goal.distance != null) goal.distance,
                      if (goal.targetDate != null) goal.targetDate,
                    ].whereType<String>().join(' · '),
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _canReactivate ? 'Switch' : goal.status.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: _canReactivate
                    ? AppColors.warmBrown
                    : AppColors.inkMuted,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CupertinoColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Switch active goal?',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make "${goal.name}" your active goal. Your current active goal will be paused.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  color: AppColors.inkMuted,
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              size: 56,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No goals yet',
              style: GoogleFonts.ebGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask the coach below to build your first training plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
