import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/share/utils/feedback_verdict_extractor.dart';

void main() {
  group('extractVerdict', () {
    test('returns null for null input', () {
      expect(extractVerdict(null), isNull);
    });

    test('returns null for empty/whitespace input', () {
      expect(extractVerdict(''), isNull);
      expect(extractVerdict('   '), isNull);
    });

    test('extracts first **bold** span', () {
      const input =
          '**Strong negative split with smooth pace control.** You opened with 5:30/km and dropped to 5:08/km in the last 3km.';
      expect(extractVerdict(input),
          'Strong negative split with smooth pace control.');
    });

    test('trims whitespace inside the bold span', () {
      const input = '**  Solid easy effort.  ** Good aerobic work.';
      expect(extractVerdict(input), 'Solid easy effort.');
    });

    test('falls back to first sentence when no bold', () {
      const input = 'Solid easy effort throughout. HR stayed in Z2.';
      expect(extractVerdict(input), 'Solid easy effort throughout');
    });

    test('strips trailing punctuation from sentence fallback', () {
      const input = 'Great pacing! You held threshold the whole way.';
      expect(extractVerdict(input), 'Great pacing');
    });

    test('uses whole string when short and no sentence terminator', () {
      const input = 'Solid effort, nice job';
      expect(extractVerdict(input), 'Solid effort, nice job');
    });

    test('returns null when very long and no bold or sentence terminator',
        () {
      final input = 'word ' * 60; // 300+ chars, no period
      expect(extractVerdict(input), isNull);
    });

    test('multi-line bold span works', () {
      const input = '**Negative split.**\n\nYou opened easy and finished hard.';
      expect(extractVerdict(input), 'Negative split.');
    });
  });
}
