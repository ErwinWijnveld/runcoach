import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/heart_rate_zones_sheet.dart';

/// Thin route screen used as the deep-link target for the yearly
/// birthday push (`birthday_zone_check`). Opens the HR-zone editor as
/// a Cupertino modal popup on mount; pops back to dashboard when the
/// sheet is dismissed.
///
/// Routes that need to open a modal-style UI from a deep link can't use
/// the modal directly (no Navigator ancestor at the route level). Wrapping
/// it in a screen with a single `addPostFrameCallback` is the cleanest
/// way to bridge the gap.
class HeartRateZonesRouteScreen extends ConsumerStatefulWidget {
  const HeartRateZonesRouteScreen({super.key});

  @override
  ConsumerState<HeartRateZonesRouteScreen> createState() =>
      _HeartRateZonesRouteScreenState();
}

class _HeartRateZonesRouteScreenState
    extends ConsumerState<HeartRateZonesRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showHeartRateZonesSheet(context);
      // Sheet closed → drop this empty shell and land the user on the
      // dashboard (rather than a weird blank screen).
      if (!mounted) return;
      context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    // The sheet covers the screen during its lifetime. We just render a
    // matching background so the post-dismiss frame doesn't flash white.
    return const ColoredBox(color: AppColors.cream);
  }
}
