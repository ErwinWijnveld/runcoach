import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/available_activity.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

/// Bottom sheet that lists nearby synced wearable runs so the user can
/// manually match one to a training day. Runs already matched to any
/// training day render with a "synced" badge and are non-tappable.
class SelectActivitySheet extends ConsumerStatefulWidget {
  final int dayId;
  final VoidCallback onMatched;

  const SelectActivitySheet({
    super.key,
    required this.dayId,
    required this.onMatched,
  });

  static Future<void> show(
    BuildContext context, {
    required int dayId,
    required VoidCallback onMatched,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectActivitySheet(
        dayId: dayId,
        onMatched: onMatched,
      ),
    );
  }

  @override
  ConsumerState<SelectActivitySheet> createState() => _SelectActivitySheetState();
}

class _SelectActivitySheetState extends ConsumerState<SelectActivitySheet> {
  /// Wearable activity id currently being matched. While non-null, all row
  /// taps are disabled to prevent double-tap races.
  int? _matchingId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(availableActivitiesProvider(widget.dayId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick an activity',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              height: 30 / 26,
                              color: AppColors.primaryInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Runs from the last week, synced from Apple Health.',
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _matchingId != null
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 20,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(radius: 14),
                  ),
                  error: (err, _) => _ErrorState(
                    message: "Couldn't load your activities.",
                    detail: '$err',
                  ),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const _ErrorState(
                        message: 'No recent activities',
                        detail:
                            "Nothing synced from Apple Health in the past week.",
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: activities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final run = activities[index];
                        final isMatchingThis =
                            _matchingId == run.wearableActivityId;
                        final disabled = run.matchedTrainingDayId != null ||
                            (_matchingId != null && !isMatchingThis);

                        return _ActivityRow(
                          run: run,
                          currentDayId: widget.dayId,
                          isMatching: isMatchingThis,
                          onTap: disabled
                              ? null
                              : () => _pickAndMatch(run.wearableActivityId),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndMatch(int wearableActivityId) async {
    if (_matchingId != null) return;

    setState(() => _matchingId = wearableActivityId);

    try {
      await ref.read(manualMatchActivityProvider.notifier).match(
            dayId: widget.dayId,
            wearableActivityId: wearableActivityId,
          );

      if (!mounted) return;
      // ManualMatchActivity bumps planVersion, which refreshes the
      // available-activities picker too.
      Navigator.of(context).pop();
      widget.onMatched();
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Couldn't match that run"),
          content: Text('$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _matchingId = null);
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  const _ErrorState({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final AvailableActivity run;
  final int currentDayId;
  final bool isMatching;
  final VoidCallback? onTap;

  const _ActivityRow({
    required this.run,
    required this.currentDayId,
    required this.isMatching,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final synced = run.matchedTrainingDayId != null;
    final syncedToThisDay = run.matchedTrainingDayId == currentDayId;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Opacity(
          opacity: (synced || (onTap == null && !isMatching)) ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.neutralHighlight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              run.name,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryInk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (synced)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: syncedToThisDay
                                    ? const Color(0xFF34C759)
                                    : AppColors.tertiary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SYNCED',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isMatching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CupertinoActivityIndicator(radius: 10),
                  )
                else
                  Text(
                    '${run.distanceKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (run.startDate != null) {
      parts.add(_formatDate(run.startDate!));
    }
    final pace = run.averagePaceSecondsPerKm;
    if (pace != null && pace > 0) {
      final mm = pace ~/ 60;
      final ss = pace % 60;
      parts.add('$mm:${ss.toString().padLeft(2, '0')} /km');
    }
    return parts.join(' · ');
  }

  String _formatDate(String iso) {
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
