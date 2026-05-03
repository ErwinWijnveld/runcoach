import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/profile_menu_sheet.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/notifications/providers/notifications_provider.dart';
import 'package:app/features/notifications/widgets/notifications_sheet.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Avatar is currently a static fallback — Apple Sign-In doesn't surface
    // a profile picture, and we removed the Strava avatar URL plumbing.
    ref.watch(authProvider);
    final pendingCount = ref.watch(pendingNotificationCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RunCoreLogo(starSize: 19, textSize: 20, gap: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NotificationsBell(
                  count: pendingCount,
                  onTap: () => showNotificationsSheet(context),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showProfileMenuSheet(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE8DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 18,
                        color: AppColors.tertiary,
                      ),
                    ),
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

class _NotificationsBell extends StatelessWidget {
  const _NotificationsBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications,
              color: AppColors.secondary,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                // Fixed 1:1 box so the badge is a perfect circle regardless
                // of the digit it contains. "9+" still fits at 9pt.
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cream, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
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
