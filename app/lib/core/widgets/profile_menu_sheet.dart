import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/router/app_router.dart';

Future<void> showProfileMenuSheet(BuildContext context) {
  // Wrap in HidesBottomNav so the native CNTabBar (UiKitView) is removed from
  // the tree while the sheet is open — otherwise its shadow bleeds through
  // the bottom edge of the sheet.
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => const HidesBottomNav(child: ProfileMenuSheet()),
  );
}

class ProfileMenuSheet extends ConsumerWidget {
  const ProfileMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            _UserHeader(
              name: user?.name ?? 'Runner',
              email: user?.email ?? '',
              profileUrl: user?.stravaProfileUrl,
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              children: [
                _SettingRow(
                  icon: CupertinoIcons.person_2,
                  label: 'Connections',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/connections');
                  },
                ),
                const _SettingRow(icon: CupertinoIcons.person_circle, label: 'Account'),
                const _SettingRow(icon: CupertinoIcons.bell, label: 'Notificaties'),
                const _SettingRow(icon: CupertinoIcons.lock, label: 'Privacy'),
                const _SettingRow(icon: CupertinoIcons.info_circle, label: 'Over'),
              ],
            ),
            const SizedBox(height: 24),
            const _DeleteButton(),
            const SizedBox(height: 8),
            const _LogoutButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? profileUrl;

  const _UserHeader({
    required this.name,
    required this.email,
    this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFECE8DC),
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: profileUrl != null
              ? Image.network(
                  profileUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _FallbackAvatar(size: 32),
                )
              : const _FallbackAvatar(size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final double size;
  const _FallbackAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: size,
        color: AppColors.tertiary,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;
  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Container(
          margin: const EdgeInsets.only(left: 52),
          height: 0.5,
          color: AppColors.inputBorder,
        ));
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SettingRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.tertiary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryInk,
                ),
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

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        onPressed: () => _confirmAndDelete(context, ref),
        child: const Text(
          'Verwijder gegevens',
          style: TextStyle(
            color: CupertinoColors.systemRed,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Verwijder gegevens',
      message:
          'Dit verwijdert je account, doelen, trainingsschema en chats. Dit kan niet ongedaan worden gemaakt.',
      confirmLabel: 'Verwijder',
      cancelLabel: 'Annuleer',
      destructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      await showAppAlert(
        context,
        title: 'Kon gegevens niet verwijderen',
        message: 'Probeer het opnieuw. ($e)',
      );
    }
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        },
        child: const Text(
          'Uitloggen',
          style: TextStyle(
            color: AppColors.primaryInk,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
