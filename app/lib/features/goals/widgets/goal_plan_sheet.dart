import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/coach/widgets/plan_content.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/goals/utils/goal_to_payload.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

/// Bottom-sheet preview of an inactive goal's plan. Mirrors the visual
/// language of [PlanDetailsSheet] (drag handle, scrollable content, sticky
/// footer) but reads from the goal's saved schedule via the goal-to-payload
/// adapter, with a single Close action — there's nothing to accept.
class GoalPlanSheet extends ConsumerWidget {
  final Goal goal;

  const GoalPlanSheet({super.key, required this.goal});

  static Future<void> show(BuildContext context, {required Goal goal}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalPlanSheet(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider(goal.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              Expanded(
                child: scheduleAsync.when(
                  loading: () => const Center(child: AppSpinner()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AppErrorState(
                        title: context.l10n.commonErrorWithMessage(e.toString()),
                      ),
                    ),
                  ),
                  data: (weeks) => SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: PlanContent(payload: goalToPlanPayload(goal, weeks)),
                  ),
                ),
              ),
              const _CloseFooter(),
            ],
          ),
        );
      },
    );
  }
}

class _CloseFooter extends StatelessWidget {
  const _CloseFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightTan,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              context.l10n.planDetailsFooterClose,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
