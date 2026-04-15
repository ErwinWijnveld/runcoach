import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
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
        color: CupertinoColors.white,
        border: Border.all(color: AppColors.warmBrown, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.doc_text,
                color: AppColors.warmBrown,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _title,
                style: const TextStyle(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isPending)
            Row(
              children: [
                Expanded(
                  child: AppFilledButton(
                    label: 'Accept',
                    onPressed: onAccept,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppBorderedButton(
                    label: 'Adjust',
                    onPressed: onReject,
                  ),
                ),
              ],
            )
          else
            Text(
              proposal.status == 'accepted' ? 'Accepted' : 'Rejected',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
