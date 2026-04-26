import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/gradient_scaffold.dart';
import 'package:app/features/organization/models/organization.dart';
import 'package:app/features/organization/providers/membership_provider.dart';

class FindOrganizationScreen extends ConsumerStatefulWidget {
  const FindOrganizationScreen({super.key});

  @override
  ConsumerState<FindOrganizationScreen> createState() =>
      _FindOrganizationScreenState();
}

class _FindOrganizationScreenState
    extends ConsumerState<FindOrganizationScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  Future<void> _request(Organization org) async {
    setState(() => _submitting = true);
    try {
      await ref.read(membershipActionsProvider.notifier).requestJoin(org.id);
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Request sent'),
          content: Text(
            'Your request to join ${org.name} has been sent. They\'ll review it soon.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not request'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(organizationSearchProvider(_query));

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSearchTextField(
                controller: _controller,
                onChanged: _onChanged,
                placeholder: 'Search by name',
              ),
            ),
            Expanded(
              child: _query.trim().length < 2
                  ? const _Hint()
                  : results.when(
                      loading: () => const AppSpinner(),
                      error: (e, _) => AppErrorState(title: 'Error: $e'),
                      data: (orgs) {
                        if (orgs.isEmpty) {
                          return const _Empty();
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: orgs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _OrgRow(
                            org: orgs[i],
                            disabled: _submitting,
                            onRequest: () => _request(orgs[i]),
                          ),
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
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: AppColors.warmBrown,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Find a coach or gym',
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

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Type at least 2 characters to search.',
          style: TextStyle(color: AppColors.warmBrown),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No organizations match that search.',
        style: TextStyle(color: AppColors.warmBrown),
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
