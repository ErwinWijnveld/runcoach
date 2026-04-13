import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

class ProposalCard extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
  });

  String get _title {
    switch (proposal.type) {
      case 'create_schedule':
        return 'Proposed: Training Plan';
      case 'modify_schedule':
        return 'Proposed: Schedule Change';
      case 'alternative_week':
        return 'Proposed: Alternative Week';
      default:
        return 'Proposal';
    }
  }

  bool get _isPending => proposal.status == 'pending';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 60, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.warmBrown, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppColors.warmBrown, size: 18),
              const SizedBox(width: 8),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Adjust'),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              proposal.status == 'accepted' ? 'Accepted' : 'Rejected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
