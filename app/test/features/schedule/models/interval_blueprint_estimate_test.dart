import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/schedule/models/interval_blueprint.dart';

/// Mirrors `api/tests/Feature/Support/IntervalBlueprintTest.php` — the
/// estimate tests use the EXACT same blueprints and expected values, so the
/// Dart port and the PHP source of truth cannot silently diverge.
void main() {
  group('IntervalBlueprint.estimateTotalKm', () {
    test('distance block with warmup and cooldown (PHP: 5.1)', () {
      const bp = IntervalBlueprint(
        warmupSeconds: 60,
        steps: [
          IntervalStep(
            type: 'block',
            reps: 4,
            workDistanceM: 800,
            workPaceSecondsPerKm: 270,
            recoverySeconds: 90,
          ),
        ],
        cooldownSeconds: 300,
      );

      expect(bp.estimateTotalKm(), 5.1);
    });

    test('duration-based work (PHP: 2.4)', () {
      const bp = IntervalBlueprint(
        steps: [
          IntervalStep(
            type: 'block',
            reps: 3,
            workDurationSeconds: 120,
            workPaceSecondsPerKm: 300,
            recoverySeconds: 60,
          ),
        ],
        cooldownSeconds: 300,
      );

      expect(bp.estimateTotalKm(), 2.4);
    });

    test('falls back to default jog pace without work paces (PHP: 3.4)', () {
      const bp = IntervalBlueprint(
        steps: [
          IntervalStep(
            type: 'block',
            reps: 4,
            workDistanceM: 400,
            recoverySeconds: 90,
          ),
        ],
        cooldownSeconds: 300,
      );

      expect(bp.estimateTotalKm(), 3.4);
    });

    test('paceless duration work uses avg work pace (PHP: 3.3)', () {
      const bp = IntervalBlueprint(
        steps: [
          IntervalStep(
            type: 'block',
            reps: 2,
            workDurationSeconds: 180,
            recoverySeconds: 90,
          ),
          IntervalStep(
            type: 'rep',
            workDistanceM: 400,
            workPaceSecondsPerKm: 240,
          ),
        ],
        cooldownSeconds: 300,
      );

      expect(bp.estimateTotalKm(), 3.3);
    });

    test('counts rest steps and clamps jog pace (PHP: 1.6)', () {
      const bp = IntervalBlueprint(
        steps: [
          IntervalStep(
            type: 'block',
            reps: 2,
            workDistanceM: 400,
            workPaceSecondsPerKm: 700,
            recoverySeconds: 90,
          ),
          IntervalStep(type: 'rest', durationSeconds: 120),
        ],
        cooldownSeconds: 300,
      );

      expect(bp.estimateTotalKm(), 1.6);
    });

    test('returns null for empty steps', () {
      expect(const IntervalBlueprint().estimateTotalKm(), isNull);
      expect(
        const IntervalBlueprint(warmupSeconds: 60, cooldownSeconds: 300)
            .estimateTotalKm(),
        isNull,
      );
    });
  });
}
