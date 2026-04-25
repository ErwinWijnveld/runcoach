import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';

part 'onboarding_api.g.dart';

@RestApi()
abstract class OnboardingApi {
  factory OnboardingApi(Dio dio) = _OnboardingApi;

  /// Returns `{status: 'ready', metrics: {...}, narrative_summary,
  /// analyzed_at, data_start_date, data_end_date}`. The first call after Strava
  /// auth runs the history sync inline on the server (30-90s), so the request
  /// can take a while — see `getProfileCall` for the timeout-overridden version.
  @GET('/onboarding/profile')
  Future<dynamic> getProfile();
}

@riverpod
OnboardingApi onboardingApi(Ref ref) => OnboardingApi(ref.watch(dioProvider));

/// First call hits the inline Strava sync on the backend (30-90s). Bypasses
/// Retrofit so we can override Dio's 30s `receiveTimeout`. After the user has
/// activities cached, the call returns instantly.
@riverpod
Future<Map<String, dynamic>> Function() getProfileCall(Ref ref) {
  final dio = ref.watch(dioProvider);
  return () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/onboarding/profile',
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return response.data ?? const {};
  };
}

/// Enqueues plan generation. Returns the PlanGeneration row in queued state
/// (or the existing in-flight row, if there is one). The screen polls
/// [pollPlanGenerationCall] for status updates. The actual agent loop runs
/// in the queue worker (~60-110s) so this POST returns in <1s.
@riverpod
Future<PlanGeneration> Function(Map<String, dynamic> body) generatePlanCall(
  Ref ref,
) {
  final dio = ref.watch(dioProvider);
  return (body) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/onboarding/generate-plan',
      data: body,
    );
    return PlanGeneration.fromJson(response.data!);
  };
}

/// Polls the latest user-actionable plan generation. Returns null when the
/// server responds 204 (nothing pending). The screen interprets null
/// mid-flight as an error condition (the row was unexpectedly cleared).
@riverpod
Future<PlanGeneration?> Function() pollPlanGenerationCall(Ref ref) {
  final dio = ref.watch(dioProvider);
  return () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/onboarding/plan-generation/latest',
    );
    if (response.statusCode == 204 || response.data == null) return null;
    return PlanGeneration.fromJson(response.data!);
  };
}
