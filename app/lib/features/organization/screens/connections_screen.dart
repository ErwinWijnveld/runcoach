import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/organization/models/membership.dart';
import 'package:app/features/organization/models/organization.dart';
import 'package:app/features/organization/providers/membership_provider.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  Timer? _debounce;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(organizationSearchProvider(_query).notifier).loadMore();
    }
  }

  Future<void> _accept(int id) async {
    try {
      await ref.read(membershipActionsProvider.notifier).acceptInvite(id);
      if (mounted) _showSnack('Joined organization');
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _reject(int id) async {
    try {
      await ref.read(membershipActionsProvider.notifier).rejectInvite(id);
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _cancelRequest(int id) async {
    try {
      await ref.read(membershipActionsProvider.notifier).cancelRequest(id);
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _leave() async {
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
      if (mounted) _showSnack('Left organization');
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e), isError: true);
    }
  }

  Future<void> _request(Organization org) async {
    setState(() => _submitting = true);
    try {
      await ref.read(membershipActionsProvider.notifier).requestJoin(org.id);
      if (mounted) _showSnack('Request sent to ${org.name}');
    } catch (e) {
      if (mounted) _showSnack(_errorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    showCupertinoDialog<void>(
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
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(membershipsProvider);
    final searchAsync = ref.watch(organizationSearchProvider(_query));

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                placeholder: 'Search gyms or clubs',
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: membershipsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (memberships) => _MembershipSection(
                        memberships: memberships,
                        onLeave: _leave,
                        onAccept: _accept,
                        onReject: _reject,
                        onCancelRequest: _cancelRequest,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _SectionTitle(
                        _query.isEmpty ? 'All organizations' : 'Results',
                      ),
                    ),
                  ),
                  ...searchAsync.when(
                    loading: () => [
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        sliver: SliverToBoxAdapter(child: AppSpinner()),
                      ),
                    ],
                    error: (e, _) => [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverToBoxAdapter(
                          child: AppErrorState(title: 'Error: $e'),
                        ),
                      ),
                    ],
                    data: (page) {
                      if (page.items.isEmpty) {
                        return [
                          const SliverPadding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            sliver: SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  'No organizations match.',
                                  style: TextStyle(color: AppColors.warmBrown),
                                ),
                              ),
                            ),
                          ),
                        ];
                      }
                      return [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList.separated(
                            itemCount: page.items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _OrgRow(
                              org: page.items[i],
                              disabled: _submitting,
                              onRequest: () => _request(page.items[i]),
                            ),
                          ),
                        ),
                        if (page.hasMore)
                          const SliverPadding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            sliver: SliverToBoxAdapter(child: AppSpinner()),
                          ),
                      ];
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
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
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: AppColors.warmBrown,
            ),
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
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.warmBrown,
        letterSpacing: 1,
      ),
    );
  }
}

class _MembershipSection extends StatelessWidget {
  final List<Membership> memberships;
  final VoidCallback onLeave;
  final Future<void> Function(int id) onAccept;
  final Future<void> Function(int id) onReject;
  final Future<void> Function(int id) onCancelRequest;

  const _MembershipSection({
    required this.memberships,
    required this.onLeave,
    required this.onAccept,
    required this.onReject,
    required this.onCancelRequest,
  });

  @override
  Widget build(BuildContext context) {
    final active = memberships.where((m) => m.isActive).toList();
    final invites = memberships.where((m) => m.isInvited).toList();
    final requests = memberships.where((m) => m.isRequested).toList();

    if (active.isEmpty && invites.isEmpty && requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isNotEmpty) ...[
            const _SectionTitle('Active membership'),
            const SizedBox(height: 8),
            _ActiveMembershipCard(
              membership: active.first,
              onLeave: onLeave,
            ),
          ],
          if (invites.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Pending invitations'),
            const SizedBox(height: 8),
            ...invites.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InviteCard(
                  membership: m,
                  onAccept: () => onAccept(m.id),
                  onReject: () => onReject(m.id),
                ),
              ),
            ),
          ],
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Pending requests'),
            const SizedBox(height: 8),
            ...requests.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RequestCard(
                  membership: m,
                  onCancel: () => onCancelRequest(m.id),
                ),
              ),
            ),
          ],
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
              if (org?.logoUrl != null && org!.logoUrl!.isNotEmpty)
                _OrgLogo(url: org.logoUrl, name: org.name, size: 40)
              else
                const Icon(Icons.business, color: AppColors.gold),
              const SizedBox(width: 12),
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
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OrgLogo(url: org?.logoUrl, name: org?.name ?? '?', size: 36),
              const SizedBox(width: 10),
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
                    Text('Invited as ${membership.role}'),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _OrgLogo(url: org?.logoUrl, name: org?.name ?? '?', size: 36),
          const SizedBox(width: 10),
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

class _OrgRow extends StatelessWidget {
  final Organization org;
  final bool disabled;
  final VoidCallback onRequest;
  const _OrgRow({
    required this.org,
    required this.disabled,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _OrgLogo(url: org.logoUrl, name: org.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (org.description != null && org.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    org.description!,
                    style: const TextStyle(color: AppColors.warmBrown),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: disabled ? null : onRequest,
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _OrgLogo extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _OrgLogo({required this.url, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.lightTan,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        alignment: Alignment.center,
        child: Text(
          _initial(name),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: AppColors.warmBrown,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _OrgLogo(url: null, name: name, size: size),
      ),
    );
  }

  String _initial(String n) {
    final t = n.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }
}
