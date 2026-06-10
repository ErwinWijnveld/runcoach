import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/dashboard/models/recent_run.dart';

Map<String, dynamic> _runJson() => {
      'id': 7,
      'source': 'apple_health',
      'source_activity_id': 'abc-123',
      'type': 'Run',
      'name': 'Riverside loop',
      'distance_meters': 8200,
      'duration_seconds': 1710,
      'average_pace_seconds_per_km': 310,
      'start_date': '2026-06-08T07:30:00+02:00',
    };

void main() {
  test('parses a linked run with a string decimal score', () {
    final entry = RecentRun.fromJson({
      'run': _runJson(),
      'training_day_id': 42,
      'compliance_score': '8.2',
    });

    expect(entry.trainingDayId, 42);
    expect(entry.complianceScore, 8.2);
    expect(entry.run.name, 'Riverside loop');
  });

  test('parses an unlinked run with null linkage', () {
    final entry = RecentRun.fromJson({
      'run': _runJson(),
      'training_day_id': null,
      'compliance_score': null,
    });

    expect(entry.trainingDayId, isNull);
    expect(entry.complianceScore, isNull);
  });

  test('DashboardData defaults to an empty recent runs list', () {
    final dashboard = DashboardData.fromJson(const {});

    expect(dashboard.recentRuns, isEmpty);
  });
}
