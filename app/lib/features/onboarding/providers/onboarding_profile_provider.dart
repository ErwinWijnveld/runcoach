import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';

part 'onboarding_profile_provider.g.dart';

/// Fetches the running profile for the onboarding overview screen. While the
/// backend is still syncing Strava history it returns `status: 'syncing'` on
/// HTTP 202 — we poll every 3s up to ~36s before giving up.
@riverpod
class OnboardingProfileController extends _$OnboardingProfileController {
  @override
  Future<OnboardingProfile> build() => _fetchUntilReady();

  Future<OnboardingProfile> _fetchUntilReady({int retries = 12}) async {
    final api = ref.read(onboardingApiProvider);
    for (var i = 0; i < retries; i++) {
      final raw = await api.getProfile();
      final profile = OnboardingProfile.fromJson(raw as Map<String, dynamic>);
      if (profile.status == 'ready') return profile;
      await Future.delayed(const Duration(seconds: 3));
    }
    throw Exception("We couldn't sync your Strava history. Try again in a moment.");
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchUntilReady);
  }
}
