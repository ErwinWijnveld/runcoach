import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons, InkWell, Material;
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/strava_activity_summary.dart';

/// Compact card showing the Strava run that was matched to a training day.
/// Renders from locally-persisted data (no Strava API call) so it works
/// offline and opens instantly. When `onOpenDetails` is provided, a black
/// round arrow button is shown in the top-right that triggers it — used on
/// the training day detail screen to navigate into the full result view.
class StravaSummaryCard extends StatelessWidget {
  final StravaActivitySummary activity;
  final VoidCallback? onOpenDetails;

  const StravaSummaryCard({
    super.key,
    required this.activity,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
      ),
      child: Material(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: Color(0xFFFC4C02),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryInk,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatStartDate(activity.startDate),
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenDetails != null) ...[
                const SizedBox(width: 8),
                _OpenDetailsButton(onTap: onOpenDetails!),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'DISTANCE',
                  value: _formatDistanceKm(activity.distanceMeters),
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'DURATION',
                  value: _formatDuration(activity.movingTimeSeconds),
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'AVG HR',
                  value: activity.averageHeartrate != null
                      ? activity.averageHeartrate!.toStringAsFixed(0)
                      : '-',
                ),
              ),
            ],
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistanceKm(int meters) {
    if (meters <= 0) return '-';
    return (meters / 1000).toStringAsFixed(2);
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '-';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatStartDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final mo = _months[dt.month - 1];
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$day $mo · $time';
    } catch (_) {
      return iso;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _OpenDetailsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OpenDetailsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            CupertinoIcons.arrow_right,
            size: 16,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryInk,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
