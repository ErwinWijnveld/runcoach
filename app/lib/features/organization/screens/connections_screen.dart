import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/organization/models/membership.dart';
import 'package:app/features/organization/providers/membership_provider.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  Future<void> _accept(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(membershipActionsProvider.notifier).acceptInvite(id);
      if (context.mounted) {
        _showSnack(context, 'Joined organization');
      }
    } catch (e) {
      if (context.mounted) _showSnack(context, _errorMessage(e), isError: true);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(membershipActionsProvider.notifier).rejectInvite(id);
    } catch (e) {
      if (context.mounted) _showSnack(context, _errorMessage(e), isError: true);
    }
  }

  Future<void> _cancelRequest(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    try {
      await ref.read(membershipActionsProvider.notifier).cancelRequest(id);
    } catch (e) {
      if (context.mounted) _showSnack(context, _errorMessage(e), isError: true);
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Leave organization?'),
        content: const Text(
          'You will lose access to your coach and any plans they created.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(membershipActionsProvider.notifier).leave();
      if (context.mounted) _showSnack(context, 'Left organization');
    } catch (e) {
      if (context.mounted) _showSnack(context, _errorMessage(e), isError: true);
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isError ? 'Error' : 'Done'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object e) {
    final s = e.toString();
    return s.length > 200 ? '${s.substring(0, 200)}…' : s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(membershipsProvider);

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: membershipsAsync.when(
                loading: () => const AppSpinner(),
                error: (err, _) => AppErrorState(
                  title: 'Error: $err',
                  onRetry: () => ref.invalidate(membershipsProvider),
                ),
                data: (memberships) {
                  final active = memberships.firstWhere(
                    (m) => m.isActive,
                    orElse: () => const Membership(
                      id: -1,
                      role: '',
                      status: '',
                    ),
                  );
                  final invites = memberships.where((m) => m.isInvited).toList();
                  final requests =
                      memberships.where((m) => m.isRequested).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      const _SectionTitle('Active membership'),
                      if (active.id == -1)
                        _NoActiveMembershipCard(
                          onFindOrg: () => context.push('/connections/find'),
                        )
                      else
                        _ActiveMembershipCard(
                          membership: active,
                          onLeave: () => _leave(context, ref),
                        ),
                      if (invites.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle('Pending invitations'),
                        ...invites.map(
                          (m) => _InviteCard(
                            membership: m,
                            onAccept: () => _accept(context, ref, m.id),
                            onReject: () => _reject(context, ref, m.id),
                          ),
                        ),
                      ],
                      if (requests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle('Pending requests'),
                        ...requests.map(
                          (m) => _RequestCard(
                            membership: m,
                            onCancel: () => _cancelRequest(context, ref, m.id),
                          ),
                        ),
                      ],
                      if (active.id == -1 && invites.isEmpty) ...[
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          onPressed: () => context.push('/connections/find'),
                          child: const Text('Find a coach or gym'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onClose,
            child: const Icon(CupertinoIcons.chevron_left, color: AppColors.warmBrown),
          ),
          const SizedBox(width: 4),
          const Text(
            'Connections',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.warmBrown,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warmBrown,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _NoActiveMembershipCard extends StatelessWidget {
  final VoidCallback onFindOrg;
  const _NoActiveMembershipCard({required this.onFindOrg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You\'re running solo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Get coached by a real human at a gym or club. Browse organizations to send a request.',
            style: TextStyle(color: AppColors.warmBrown),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onFindOrg,
            child: const Text('Find an organization'),
          ),
        ],
      ),
    );
  }
}

class _ActiveMembershipCard extends StatelessWidget {
  final Membership membership;
  final VoidCallback onLeave;
  const _ActiveMembershipCard({
    required this.membership,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final org = membership.organization;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  org?.name ?? 'Organization',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Role: ${membership.role}'),
          if (membership.coach != null) ...[
            const SizedBox(height: 4),
            Text('Coach: ${membership.coach!.name}'),
          ],
          const SizedBox(height: 16),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onLeave,
            child: const Text(
              'Leave organization',
              style: TextStyle(color: AppColors.warmBrown),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Membership membership;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _InviteCard({
    required this.membership,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final org = membership.organization;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            org?.name ?? 'Organization',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text('Invited as ${membership.role}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: onAccept,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                onPressed: onReject,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Reject',
                  style: TextStyle(color: AppColors.warmBrown),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Membership membership;
  final VoidCallback onCancel;
  const _RequestCard({required this.membership, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final org = membership.organization;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org?.name ?? 'Organization',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text('Awaiting approval'),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.warmBrown),
            ),
          ),
        ],
      ),
    );
  }
}
