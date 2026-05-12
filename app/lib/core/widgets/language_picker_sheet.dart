import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/i18n/locale_provider.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/router/app_router.dart' show HidesBottomNav;

Future<void> showLanguagePickerSheet(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => const HidesBottomNav(child: _LanguagePickerSheet()),
  );
}

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncLocale = ref.watch(appLocaleProvider);
    final activeCode = asyncLocale.value?.languageCode;

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
            const SizedBox(height: 16),
            Text(
              l10n.settingsLanguageTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.settingsLanguageSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _OptionsCard(
              children: [
                _LanguageRow(
                  label: l10n.settingsLanguageEnglish,
                  active: activeCode == 'en',
                  onTap: () => _select(ref, context, const Locale('en')),
                ),
                _LanguageRow(
                  label: l10n.settingsLanguageDutch,
                  active: activeCode == 'nl',
                  onTap: () => _select(ref, context, const Locale('nl')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OptionsCard(
              children: [
                _LanguageRow(
                  label: l10n.settingsLanguageAuto,
                  subtitle: l10n.settingsLanguageAutoSubtitle,
                  active: false,
                  onTap: () => _select(ref, context, null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.commonClose,
                  style: const TextStyle(
                    color: AppColors.primaryInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, BuildContext context, Locale? locale) async {
    await ref.read(appLocaleProvider.notifier).setOverride(locale);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _OptionsCard extends StatelessWidget {
  final List<Widget> children;
  const _OptionsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Container(
          margin: const EdgeInsets.only(left: 16),
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

class _LanguageRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool active;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    this.subtitle,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.primaryInk,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (active)
              const Icon(
                CupertinoIcons.check_mark,
                size: 18,
                color: AppColors.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
