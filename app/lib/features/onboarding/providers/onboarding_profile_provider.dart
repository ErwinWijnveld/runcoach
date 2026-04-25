import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_profile.dart';

part 'onboarding_profile_provider.g.dart';

/// Fetches the running profile for the onboarding overview screen. The first
/// call after Strava auth blocks on a server-side inline Strava history sync
/// (30-90s) and returns `status: 'ready'` directly — no polling needed.
@riverpod
class OnboardingProfileController extends _$OnboardingProfileController {
  @override
  Future<OnboardingProfile> build() => _fetch();

  Future<OnboardingProfile> _fetch() async {
    final getProfile = ref.read(getProfileCallProvider);
    final raw = await getProfile();
    return OnboardingProfile.fromJson(raw);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
