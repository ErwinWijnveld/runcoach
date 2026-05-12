import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/organization/providers/membership_provider.dart';

class InviteDetailScreen extends ConsumerStatefulWidget {
  final String token;
  const InviteDetailScreen({super.key, required this.token});

  @override
  ConsumerState<InviteDetailScreen> createState() =>
      _InviteDetailScreenState();
}

class _InviteDetailScreenState extends ConsumerState<InviteDetailScreen> {
  bool _accepting = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await ref
          .read(membershipActionsProvider.notifier)
          .acceptInviteByToken(widget.token);
      if (mounted) context.go('/connections');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _accepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.envelope_badge_fill,
                size: 64,
                color: AppColors.gold,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.orgInviteTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.orgInviteBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.warmBrown),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_accepting)
                const AppSpinner()
              else
                CupertinoButton.filled(
                  onPressed: _accept,
                  child: Text(context.l10n.orgInviteAccept),
                ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => context.go('/connections'),
                child: Text(
                  context.l10n.orgInviteLater,
                  style: const TextStyle(color: AppColors.warmBrown),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
