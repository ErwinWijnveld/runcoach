import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'onboarding_api.g.dart';

@RestApi()
abstract class OnboardingApi {
  factory OnboardingApi(Dio dio) = _OnboardingApi;

  /// Returns `{status: 'syncing'}` (HTTP 202) while Strava history is still
  /// being fetched, or `{status: 'ready', metrics: {...}, narrative_summary,
  /// analyzed_at, data_start_date, data_end_date}` once the profile is cached.
  @GET('/onboarding/profile')
  Future<dynamic> getProfile();
}

@riverpod
OnboardingApi onboardingApi(Ref ref) => OnboardingApi(ref.watch(dioProvider));

/// Plan generation routinely takes 30-90s — the Anthropic call streams a
/// full schedule JSON. Bypasses Retrofit so we can override Dio's 30s
/// `receiveTimeout` without polluting every request.
///
/// Returns the raw decoded JSON body: `{conversation_id, proposal_id, weeks}`.
@riverpod
Future<Map<String, dynamic>> Function(Map<String, dynamic> body) generatePlanCall(
  Ref ref,
) {
  final dio = ref.watch(dioProvider);
  return (body) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/onboarding/generate-plan',
      data: body,
      options: Options(
        receiveTimeout: const Duration(minutes: 4),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    return response.data ?? const {};
  };
}
