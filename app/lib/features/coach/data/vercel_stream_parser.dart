import 'dart:convert';

import 'package:app/features/coach/models/coach_chip.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/models/coach_stats_card.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

class VercelStreamParser {
  static const _humanizedTools = {
    'GetRecentRuns': 'Looking up your recent runs…',
    'SearchStravaActivities': 'Looking up your activities…',
    'GetActivityDetails': 'Digging into that run…',
    'GetCurrentSchedule': 'Loading your schedule…',
    'GetRaceInfo': 'Checking your race…',
    'GetComplianceReport': 'Reviewing compliance…',
    'CreateSchedule': 'Building your training plan…',
    'ModifySchedule': 'Adjusting your schedule…',
    'GetRunningProfile': 'Analysing your running history…',
    'PresentRunningStats': 'Preparing your stats…',
    'OfferChoices': 'Preparing options…',
  };

  Stream<VercelStreamEvent> parse(Stream<List<int>> bytes) async* {
    final buffer = StringBuffer();

    await for (final chunk in bytes.cast<List<int>>().transform(utf8.decoder)) {
      buffer.write(chunk);
      final text = buffer.toString();
      final boundary = text.lastIndexOf('\n\n');
      if (boundary == -1) continue;

      final complete = text.substring(0, boundary + 2);
      final remainder = text.substring(boundary + 2);

      buffer
        ..clear()
        ..write(remainder);

      for (final block in complete.split('\n\n')) {
        if (block.isEmpty) continue;

        for (final line in block.split('\n')) {
          if (line.startsWith(':')) continue;
          if (!line.startsWith('data: ')) continue;

          final payload = line.substring(6);
          if (payload == '[DONE]') {
            yield const VercelStreamEvent.done();
            return;
          }

          final event = _parseEvent(payload);
          if (event != null) yield event;
        }
      }
    }

    final tail = buffer.toString().trim();
    if (tail.startsWith('data: ')) {
      final payload = tail.substring(6);
      if (payload == '[DONE]') {
        yield const VercelStreamEvent.done();
      }
    }
  }

  VercelStreamEvent? _parseEvent(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == null) return null;

      return switch (type) {
        'text-delta' => VercelStreamEvent.textDelta(json['delta'] as String),
        'tool-input-available' => VercelStreamEvent.toolStart(
            _humanize(json['toolName'] as String? ?? ''),
          ),
        'tool-output-available' => const VercelStreamEvent.toolEnd(),
        'error' => VercelStreamEvent.error(
            json['errorText'] as String? ?? 'Unknown error',
          ),
        'data-proposal' => VercelStreamEvent.proposal(
            CoachProposal.fromJson(json['data'] as Map<String, dynamic>),
          ),
        'data-stats' => VercelStreamEvent.stats(
            CoachStatsCard(
              metrics:
                  (json['data']['metrics'] as Map).cast<String, dynamic>(),
            ),
          ),
        'data-chips' => VercelStreamEvent.chips(
            (json['data']['chips'] as List)
                .map(
                  (c) =>
                      CoachChip.fromJson(Map<String, dynamic>.from(c as Map)),
                )
                .toList(),
          ),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  String _humanize(String toolName) =>
      _humanizedTools[toolName] ?? 'Working on it…';
}
