import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/auth/models/user.dart';

void main() {
  group('PlanGeneration JSON parsing', () {
    test('parses queued status with null fields', () {
      final json = {
        'id': 7,
        'status': 'queued',
        'conversation_id': null,
        'proposal_id': null,
        'error_message': null,
      };

      final pg = PlanGeneration.fromJson(json);

      expect(pg.id, 7);
      expect(pg.status, PlanGenerationStatus.queued);
      expect(pg.conversationId, isNull);
      expect(pg.proposalId, isNull);
      expect(pg.errorMessage, isNull);
    });

    test('parses processing status', () {
      final pg = PlanGeneration.fromJson({
        'id': 1,
        'status': 'processing',
        'conversation_id': null,
        'proposal_id': null,
        'error_message': null,
      });
      expect(pg.status, PlanGenerationStatus.processing);
    });

    test('parses completed status with conversation + proposal ids', () {
      final pg = PlanGeneration.fromJson({
        'id': 42,
        'status': 'completed',
        'conversation_id': 'abc-123-def',
        'proposal_id': 99,
        'error_message': null,
      });

      expect(pg.status, PlanGenerationStatus.completed);
      expect(pg.conversationId, 'abc-123-def');
      expect(pg.proposalId, 99);
    });

    test('parses failed status with error message', () {
      final pg = PlanGeneration.fromJson({
        'id': 5,
        'status': 'failed',
        'conversation_id': null,
        'proposal_id': null,
        'error_message': 'Anthropic API timeout',
      });

      expect(pg.status, PlanGenerationStatus.failed);
      expect(pg.errorMessage, 'Anthropic API timeout');
    });

    test('round-trips through toJson + fromJson', () {
      const original = PlanGeneration(
        id: 12,
        status: PlanGenerationStatus.completed,
        conversationId: 'cid-uuid',
        proposalId: 34,
        errorMessage: null,
      );

      final json = original.toJson();
      expect(json['status'], 'completed');
      expect(json['conversation_id'], 'cid-uuid');
      expect(json['proposal_id'], 34);

      final restored = PlanGeneration.fromJson(json);
      expect(restored, original);
    });

    test('emits correct JSON value for each status enum', () {
      // Belt-and-suspenders for the @JsonValue mapping — if anyone
      // changes case names without re-mapping, this catches it.
      expect(
        const PlanGeneration(id: 1, status: PlanGenerationStatus.queued).toJson()['status'],
        'queued',
      );
      expect(
        const PlanGeneration(id: 1, status: PlanGenerationStatus.processing).toJson()['status'],
        'processing',
      );
      expect(
        const PlanGeneration(id: 1, status: PlanGenerationStatus.completed).toJson()['status'],
        'completed',
      );
      expect(
        const PlanGeneration(id: 1, status: PlanGenerationStatus.failed).toJson()['status'],
        'failed',
      );
    });
  });

  group('User JSON parsing — pendingPlanGeneration', () {
    test('parses user payload with pending_plan_generation field', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Erwin',
        'email': 'e@example.com',
        'strava_athlete_id': 12345,
        'strava_profile_url': null,
        'coach_style': 'balanced',
        'has_completed_onboarding': false,
        'pending_plan_generation': {
          'id': 9,
          'status': 'processing',
          'conversation_id': null,
          'proposal_id': null,
          'error_message': null,
        },
      });

      expect(user.pendingPlanGeneration, isNotNull);
      expect(user.pendingPlanGeneration!.status, PlanGenerationStatus.processing);
      expect(user.pendingPlanGeneration!.id, 9);
    });

    test('parses user payload with explicit null pending_plan_generation', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Erwin',
        'email': 'e@example.com',
        'strava_athlete_id': null,
        'strava_profile_url': null,
        'coach_style': null,
        'has_completed_onboarding': true,
        'pending_plan_generation': null,
      });

      expect(user.pendingPlanGeneration, isNull);
    });

    test('parses user payload with omitted pending_plan_generation field', () {
      // Backwards-compatibility: older API responses didn't include the
      // field at all. Freezed should treat absent the same as null.
      final user = User.fromJson({
        'id': 1,
        'name': 'Erwin',
        'email': 'e@example.com',
        'strava_athlete_id': null,
        'strava_profile_url': null,
        'coach_style': null,
        'has_completed_onboarding': true,
      });

      expect(user.pendingPlanGeneration, isNull);
    });

    test('parses completed pending_plan_generation with all fields populated', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Erwin',
        'email': 'e@example.com',
        'strava_athlete_id': null,
        'strava_profile_url': null,
        'coach_style': 'balanced',
        'has_completed_onboarding': false,
        'pending_plan_generation': {
          'id': 17,
          'status': 'completed',
          'conversation_id': '550e8400-e29b-41d4-a716-446655440000',
          'proposal_id': 88,
          'error_message': null,
        },
      });

      expect(user.pendingPlanGeneration!.status, PlanGenerationStatus.completed);
      expect(user.pendingPlanGeneration!.conversationId,
          '550e8400-e29b-41d4-a716-446655440000');
      expect(user.pendingPlanGeneration!.proposalId, 88);
    });

    test('parses failed pending_plan_generation with error message', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Erwin',
        'email': 'e@example.com',
        'strava_athlete_id': null,
        'strava_profile_url': null,
        'coach_style': 'balanced',
        'has_completed_onboarding': false,
        'pending_plan_generation': {
          'id': 5,
          'status': 'failed',
          'conversation_id': null,
          'proposal_id': null,
          'error_message': 'Generation timed out',
        },
      });

      expect(user.pendingPlanGeneration!.status, PlanGenerationStatus.failed);
      expect(user.pendingPlanGeneration!.errorMessage, 'Generation timed out');
    });
  });
}
