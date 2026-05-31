import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';

/// Post-onboarding "see your plan + paywall" moment.
///
/// The user has just generated a training plan. We show weeks 1–4 in full
/// detail as a teaser, blur weeks 5+ with a lock overlay, and present the
/// RevenueCat paywall on any unlock tap or via the persistent bottom CTA.
///
/// Hard paywall — no skip button, no back navigation. After a successful
/// purchase we navigate to the coach chat that was created during plan
/// generation. The route guard in [app_router.dart] keeps non-pro users
/// pinned to this screen even on cold start.
class PlanPreviewScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const PlanPreviewScreen({super.key, required this.conversationId});

  @override
  ConsumerState<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends ConsumerState<PlanPreviewScreen> {
  /// Number of weeks visible without paying. After the 4th week, the rest are
  /// rendered behind a blur + lock overlay.
  static const int _freeWeeks = 4;

  bool _paywallOpen = false;

  Future<void> _presentPaywall() async {
    if (_paywallOpen) return;
    _paywallOpen = true;
    try {
      final result = await RevenueCatUI.presentPaywall(
        // Hard paywall — no escape hatch on the modal itself either.
        displayCloseButton: false,
      );
      if (!mounted) return;
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        // Send the client claim: in production RC REST is authoritative; in
        // local dev (Test Store) the server trusts the claim so the gate
        // matches the SDK.
        await ref
            .read(proEntitlementProvider.notifier)
            .syncFromServer(fromPurchase: true);
        if (!mounted) return;
        // Belt-and-braces for local dev: if the server still doesn't see us as
        // pro, fall back to the SDK's client-side entitlement for navigation.
        if (!ref.read(proEntitlementProvider).isPro) {
          await ref.read(proEntitlementProvider.notifier).refreshFromClient();
          if (!mounted) return;
        }
        if (ref.read(proEntitlementProvider).isPro) {
          context.go('/coach/chat/${widget.conversationId}');
        }
      }
    } finally {
      _paywallOpen = false;
    }
  }

  /// Debug-only shortcut: simulate a successful payment without going through
  /// the RevenueCat (Test Store) purchase sheet. Grants the entitlement
  /// server-side via the local-only dev endpoint and advances to the coach
  /// chat — exactly like a real successful purchase. Never shown in
  /// release/TestFlight builds (gated on kDebugMode) and the endpoint 404s
  /// outside local env.
  Future<void> _simulatePayment() async {
    await ref.read(proEntitlementProvider.notifier).devActivate();
    if (!mounted) return;
    if (ref.read(proEntitlementProvider).isPro) {
      context.go('/coach/chat/${widget.conversationId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dashboardAsync = ref.watch(dashboardProvider);

    return PopScope(
      // Hard paywall — block the iOS swipe-back gesture too. Quitting the
      // app is the user's only escape.
      canPop: false,
      child: GradientScaffold(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _PreviewHeader(
                    title: l10n.paywallPreviewTitle,
                    subtitle: dashboardAsync.value?.activeGoal?.name,
                  ),
                  Expanded(
                    child: dashboardAsync.when(
                      loading: () => const AppSpinner(),
                      error: (err, _) => AppErrorState(
                        title: context.l10n.commonErrorWithMessage(
                          err.toString(),
                        ),
                      ),
                      data: (dashboard) {
                        final goalId = dashboard.activeGoal?.id;
                        if (goalId == null) {
                          // Defensive: this screen should only be entered with
                          // a fresh goal. If somehow not, surface the paywall
                          // anyway and let the runner unlock.
                          return Center(
                            child: CupertinoButton.filled(
                              onPressed: _presentPaywall,
                              child: Text(l10n.paywallUnlockCta),
                            ),
                          );
                        }
                        final weeksAsync =
                            ref.watch(scheduleProvider(goalId));
                        return weeksAsync.when(
                          loading: () => const AppSpinner(),
                          error: (err, _) => AppErrorState(
                            title: context.l10n.commonErrorWithMessage(
                              err.toString(),
                            ),
                          ),
                          data: (weeks) => _WeekList(
                            weeks: weeks,
                            freeWeeks: _freeWeeks,
                            onLockedTap: _presentPaywall,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _UnlockCta(
                  onTap: _presentPaywall,
                  onSimulatePayment: kDebugMode ? _simulatePayment : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PreviewHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.goldGlow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.l10n.paywallEyebrow,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.eyebrow,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.ebGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
              height: 1.1,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekList extends StatelessWidget {
  final List<TrainingWeek> weeks;
  final int freeWeeks;
  final VoidCallback onLockedTap;

  const _WeekList({
    required this.weeks,
    required this.freeWeeks,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return Center(child: Text(context.l10n.schedNoTrainingWeek));
    }
    return ListView.separated(
      // Leave room at the bottom so the last card clears the pinned CTA bar.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      itemCount: weeks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final week = weeks[index];
        final locked = index >= freeWeeks;
        final card = _WeekCard(week: week);
        if (!locked) return card;
        return _LockedWeek(card: card, onTap: onLockedTap);
      },
    );
  }
}

class _WeekCard extends StatelessWidget {
  final TrainingWeek week;

  const _WeekCard({required this.week});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = week.trainingDays ?? const <TrainingDay>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A37280F),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.paywallWeekEyebrow(week.weekNumber),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.eyebrow,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.paywallWeekTotalKm(_formatKm(week.totalKm)),
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            week.focus,
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          if (days.isEmpty)
            Text(
              l10n.paywallNoDaysPlaceholder,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final d in days) _DayPill(day: d)],
            ),
        ],
      ),
    );
  }

  String _formatKm(double km) {
    if (km == km.roundToDouble()) return km.toStringAsFixed(0);
    return km.toStringAsFixed(1);
  }
}

class _DayPill extends StatelessWidget {
  final TrainingDay day;

  const _DayPill({required this.day});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(day.date);
    final dow = date != null ? DateFormat.E().format(date) : '';
    final km = day.targetKm;
    final body = km != null && km > 0
        ? '$dow · ${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)}km'
        : dow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightTan,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        body,
        style: GoogleFonts.publicSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}

class _LockedWeek extends StatelessWidget {
  final Widget card;
  final VoidCallback onTap;

  const _LockedWeek({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Render the real card so silhouettes/sizes match week 1–4. The
            // blur on top makes day pills unreadable while keeping the
            // layout consistent.
            card,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: ColoredBox(
                  color: const Color(0xCCFAF8F4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1437280F),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.lock_fill,
                            size: 14,
                            color: AppColors.primaryInk,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.paywallLockedHint,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ],
                      ),
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
}

class _UnlockCta extends StatelessWidget {
  final VoidCallback onTap;

  /// Debug-only: when non-null, renders a "Simulate payment" button below the
  /// real CTA. Wired to a local-dev endpoint so the paywall flow is testable
  /// without a real transaction. Null in release/TestFlight builds.
  final VoidCallback? onSimulatePayment;

  const _UnlockCta({required this.onTap, this.onSimulatePayment});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.neutral,
                minimumSize: const Size.fromHeight(52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                context.l10n.paywallUnlockCta,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            if (onSimulatePayment != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 6),
                onPressed: onSimulatePayment,
                child: const Text(
                  '🛠 Simulate payment (dev)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
