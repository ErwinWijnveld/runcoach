import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/available_strava_activity.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';

/// Bottom sheet that lists recent Strava runs so the user can manually match
/// one to the training day when the webhook didn't auto-sync. Runs already
/// matched to any training day (this one or another) render with a "synced"
/// badge and are non-tappable.
class SelectStravaRunSheet extends ConsumerStatefulWidget {
  final int dayId;
  final VoidCallback onMatched;

  const SelectStravaRunSheet({
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
      builder: (_) => SelectStravaRunSheet(
        dayId: dayId,
        onMatched: onMatched,
      ),
    );
  }

  @override
  ConsumerState<SelectStravaRunSheet> createState() =>
      _SelectStravaRunSheetState();
}

class _SelectStravaRunSheetState extends ConsumerState<SelectStravaRunSheet> {
  /// Strava activity id currently being matched. While non-null, all row
  /// taps are disabled to prevent double-tap races.
  int? _matchingId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(availableStravaActivitiesProvider(widget.dayId));

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
                            'Pick a Strava run',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              height: 30 / 26,
                              color: AppColors.primaryInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Runs from the last week, fetched live from Strava.",
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
                    message: "Couldn't load your Strava runs.",
                    detail: '$err',
                  ),
                  data: (result) {
                    if (result.hasError) {
                      return _ErrorState(
                        message: _errorTitle(result.errorCode!),
                        detail: _errorDetail(result.errorCode!),
                      );
                    }
                    if (result.activities.isEmpty) {
                      return const _ErrorState(
                        message: 'No recent Strava runs',
                        detail:
                            "Nothing logged in Strava in the past week. Go run!",
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: result.activities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final run = result.activities[index];
                        final isMatchingThis =
                            _matchingId == run.stravaActivityId;
                        final disabled = run.matchedTrainingDayId != null ||
                            (_matchingId != null && !isMatchingThis);

                        return _RunRow(
                          run: run,
                          currentDayId: widget.dayId,
                          isMatching: isMatchingThis,
                          onTap: disabled
                              ? null
                              : () => _pickAndMatch(run.stravaActivityId),
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

  Future<void> _pickAndMatch(int stravaActivityId) async {
    if (_matchingId != null) return;

    setState(() => _matchingId = stravaActivityId);

    try {
      await ref
          .read(manualMatchStravaActivityProvider.notifier)
          .match(dayId: widget.dayId, stravaActivityId: stravaActivityId);

      if (!mounted) return;
      // Make a future reopening of the sheet show the run as now-synced.
      ref.invalidate(availableStravaActivitiesProvider(widget.dayId));

      Navigator.of(context).pop();
      widget.onMatched();
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text("Couldn't sync that run"),
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

  String _errorTitle(String code) => switch (code) {
        'strava_disconnected' => 'Strava not connected',
        'rate_limited' => 'Slow down a sec',
        _ => "Couldn't reach Strava",
      };

  String _errorDetail(String code) => switch (code) {
        'strava_disconnected' =>
          'Reconnect your Strava account in Settings to pick a run.',
        'rate_limited' =>
          "You've hit Strava's rate limit. Try again in a couple of minutes.",
        _ => 'Strava is unreachable right now. Try again in a moment.',
      };
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

class _RunRow extends StatelessWidget {
  final AvailableStravaActivity run;
  final int currentDayId;
  final bool isMatching;
  final VoidCallback? onTap;

  const _RunRow({
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
