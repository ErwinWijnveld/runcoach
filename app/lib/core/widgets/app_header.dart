import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/profile_menu_sheet.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

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
                const Icon(
                  Icons.notifications,
                  color: AppColors.secondary,
                  size: 24,
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
                    child: _Avatar(url: user?.stravaProfileUrl),
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

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _fallback();
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: 18,
        color: AppColors.tertiary,
      ),
    );
  }
}
