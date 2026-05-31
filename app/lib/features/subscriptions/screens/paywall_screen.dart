import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/subscriptions/providers/pro_entitlement_provider.dart';

/// Hard paywall for an already-onboarded runner with no active Pro
/// entitlement — a lapsed subscriber, an admin-revoked user, or a
/// pre-subscriptions (grandfathered) user opening the app for the first time
/// since subscriptions shipped.
///
/// Unlike [PlanPreviewScreen] there is no freshly-generated plan to tease, so
/// this is a bare value-prop screen: the RevenueCat paywall auto-presents on
/// mount, and a fallback CTA re-opens it if dismissed (or if the RC sheet
/// errors — e.g. while the Paid Apps Agreement is still processing). On a
/// successful purchase/restore we sync and route to the dashboard.
///
/// Hard paywall — no close button, no back navigation (the router redirect
/// keeps sending the user here until they're Pro).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _paywallOpen = false;
  bool _autoPresented = false;

  @override
  void initState() {
    super.initState();
    // Auto-present once after the screen is on-screen. We don't re-force it on
    // dismiss — the runner can re-open via the CTA, so they can read the
    // value prop without the sheet snapping back instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          context.go('/dashboard');
        }
      }
    } finally {
      _paywallOpen = false;
    }
  }

  /// Debug-only: grant the entitlement via the local-only dev endpoint and
  /// advance to the dashboard, bypassing the RevenueCat sheet. Never shown in
  /// release builds.
  Future<void> _simulatePayment() async {
    await ref.read(proEntitlementProvider.notifier).devActivate();
    if (!mounted) return;
    if (ref.read(proEntitlementProvider).isPro) {
      context.go('/dashboard');
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bolt_fill,
                    size: 34,
                    color: AppColors.warmBrown,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.paywallLapsedTitle,
                  textAlign: TextAlign.center,
                  style: RunCoreText.serifTitle(size: 30).copyWith(height: 1.15),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.paywallLapsedSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkMuted,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _presentPaywall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.neutral,
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.paywallUnlockCta,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    onPressed: _simulatePayment,
                    child: const Text(
                      '🛠 Simulate payment (dev)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
