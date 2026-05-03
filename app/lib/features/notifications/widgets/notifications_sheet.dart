import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ElevatedButton, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/heart_rate_zones_sheet.dart';
import 'package:app/features/notifications/models/user_notification.dart';
import 'package:app/features/notifications/providers/notifications_provider.dart';
import 'package:app/router/app_router.dart';

Future<void> showNotificationsSheet(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => const HidesBottomNav(child: _NotificationsSheet()),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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
              const SizedBox(height: 18),
              Text(
                'NOTIFICATIONS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.96,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: state.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load notifications.\n$e',
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        color: AppColors.inkMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _NotificationCard(notification: items[i]),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.bell_slash,
            size: 36,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up.',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard({required this.notification});

  final UserNotification notification;

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A37280F),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _typeLabel(n.type),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.eyebrow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            n.title,
            style: GoogleFonts.ebGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryInk,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            n.body,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              height: 1.45,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'DISMISS',
                  onPressed: _busy
                      ? null
                      : () => _act(() => ref
                          .read(notificationsProvider.notifier)
                          .dismiss(n.id)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: 'APPLY',
                  busy: _busy,
                  onPressed: _busy
                      ? null
                      : () => _act(() => ref
                          .read(notificationsProvider.notifier)
                          .accept(n.id)),
                ),
              ),
            ],
          ),
          // Pace-adjustment notifications are triggered by an HR mismatch.
          // Surface a tertiary action so the runner can recalibrate their
          // zones directly — addresses the root cause rather than just
          // patching pace. Stacks under (not next to) the primary actions
          // because it's a navigation action, not a decision on this card.
          if (n.type == 'pace_adjustment') ...[
            const SizedBox(height: 8),
            _TertiaryButton(
              label: 'Edit HR Zones',
              icon: Icons.edit_outlined,
              onPressed: _busy ? null : () => showHeartRateZonesSheet(context),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'pace_adjustment' => 'PACE ADJUSTMENT',
        _ => type.replaceAll('_', ' ').toUpperCase(),
      };
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.neutral,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(
                color: CupertinoColors.white,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.neutral,
              ),
            ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightTan,
        foregroundColor: AppColors.primaryInk,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.primaryInk,
        ),
      ),
    );
  }
}

/// Compact full-width text-link button used for tertiary navigation
/// actions inside a card (e.g. "Edit HR Zones"). Smaller vertical
/// padding + icon + text-style label keeps it visually subordinate to
/// the primary/secondary CTAs above it.
class _TertiaryButton extends StatelessWidget {
  const _TertiaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.tertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
