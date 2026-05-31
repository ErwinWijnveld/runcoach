import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/coach/widgets/plan_content.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';

/// Post-onboarding "see your plan + paywall" moment.
///
/// The user has just generated a training plan that exists as a PENDING
/// proposal (not an active goal yet). We render the same rich [PlanContent]
/// the coach chat "view schedule" uses — header, feasibility bar, weekly
/// volume chart, top stats — with the first [_freeWeeks] week cards visible
/// and the rest behind a frosted-blur lock. The RevenueCat paywall
/// auto-presents shortly after the plan is shown, and re-opens on any tap of
/// the locked section or the bottom CTA.
///
/// Hard paywall — no skip button, no back navigation. After a successful
/// purchase we navigate to the coach chat created during plan generation.
class PlanPreviewScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const PlanPreviewScreen({super.key, required this.conversationId});

  @override
  ConsumerState<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends ConsumerState<PlanPreviewScreen> {
  /// Number of fully-visible week cards before the locked/blurred section.
  static const int _freeWeeks = 3;

  /// Delay before the paywall auto-presents, giving the runner a few seconds
  /// to take in their plan before the modal slides up over it.
  static const Duration _autoPresentDelay = Duration(seconds: 4);

  late final Future<PlanGeneration?> _generationFuture;
  bool _paywallOpen = false;
  bool _autoPresented = false;

  @override
  void initState() {
    super.initState();
    _generationFuture = ref.read(pollPlanGenerationCallProvider)();
    // One auto-present after the preview is on screen. We do NOT re-force it
    // if the runner dismisses the sheet — they can re-open via the CTA / the
    // locked section, so they're free to study the teaser.
    Future.delayed(_autoPresentDelay, () {
      if (!mounted || _autoPresented) return;
      _autoPresented = true;
      _presentPaywall();
    });
  }

  Future<void> _presentPaywall() async {
    if (_paywallOpen) return;
    _paywallOpen = true;
    try {
      final result = await RevenueCatUI.presentPaywall(
        displayCloseButton: false,
      );
      if (!mounted) return;
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        // Production: RC REST is authoritative. Local dev (Test Store): the
        // server trusts the posted claim so the gate matches the SDK.
        await ref
            .read(proEntitlementProvider.notifier)
            .syncFromServer(fromPurchase: true);
        if (!mounted) return;
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

  /// Debug-only shortcut: simulate a successful payment without the RevenueCat
  /// (Test Store) sheet. Grants the entitlement via the local-only dev
  /// endpoint and advances to the coach chat. Never shown in release builds.
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

    return PopScope(
      // Hard paywall — block the iOS swipe-back gesture too.
      canPop: false,
      child: GradientScaffold(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              FutureBuilder<PlanGeneration?>(
                future: _generationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const AppSpinner();
                  }
                  final payload = snapshot.data?.proposal?.payload;
                  if (payload == null) {
                    // Defensive: no proposal payload (shouldn't happen
                    // post-generation). Let the runner unlock anyway.
                    return Center(
                      child: CupertinoButton.filled(
                        onPressed: _presentPaywall,
                        child: Text(l10n.paywallUnlockCta),
                      ),
                    );
                  }
                  // PlanContent's own header already shows the eyebrow
                  // ("Recommended plan") + goal name, so there's no
                  // screen-level title — the component is the whole overview.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    child: PlanContent(
                      payload: payload,
                      previewWeekCount: _freeWeeks,
                      onUnlock: _presentPaywall,
                      cardColor: CupertinoColors.white,
                    ),
                  );
                },
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

class _UnlockCta extends StatelessWidget {
  final VoidCallback onTap;

  /// Debug-only: when non-null, renders a "Simulate payment" button below the
  /// real CTA. Null in release/TestFlight builds.
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
