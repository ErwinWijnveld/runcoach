import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/screens/onboarding_form_screen.dart';

void main() {
  group('parseGoalTimeInput', () {
    test('parses HH:MM:SS', () {
      expect(parseGoalTimeInput('1:45:00', null), 6300);
      expect(parseGoalTimeInput('01:45:00', null), 6300);
      expect(parseGoalTimeInput('3:20:15', null), 3 * 3600 + 20 * 60 + 15);
    });

    test('parses MM:SS as total time when minutes >= 15', () {
      expect(parseGoalTimeInput('25:30', 5000), 25 * 60 + 30);
      expect(parseGoalTimeInput('45:00', 10000), 45 * 60);
    });

    test('parses MM:SS as pace when minutes < 15 and distance known', () {
      // 5:30 / km at 10000m → 10 * (5*60+30) = 3300 sec
      expect(parseGoalTimeInput('5:30', 10000), 3300);
      // 4:00 / km at 21097m → 21.097 * 240 ≈ 5063 sec
      expect(parseGoalTimeInput('4:00', 21097), 5063);
    });

    test('parses pace with /km suffix', () {
      expect(parseGoalTimeInput('5:30/km', 10000), 3300);
      expect(parseGoalTimeInput('5:30 /km', 10000), 3300);
      expect(parseGoalTimeInput('5:30min/km', 10000), 3300);
    });

    test('parses hour + minute shorthand', () {
      expect(parseGoalTimeInput('1h 45m', null), 6300);
      expect(parseGoalTimeInput('1h45m', null), 6300);
      expect(parseGoalTimeInput('1h45min', null), 6300);
      expect(parseGoalTimeInput('2h', null), 7200);
      expect(parseGoalTimeInput('45min', null), 2700);
      expect(parseGoalTimeInput('45m', null), 2700);
    });

    test('returns null for unparseable input', () {
      expect(parseGoalTimeInput('', null), isNull);
      expect(parseGoalTimeInput('fast', null), isNull);
      expect(parseGoalTimeInput('1:75:00', null), isNull);
      expect(parseGoalTimeInput(':30', null), isNull);
    });

    test('returns null for pace without distance', () {
      expect(parseGoalTimeInput('5:30/km', null), isNull);
    });
  });
}
