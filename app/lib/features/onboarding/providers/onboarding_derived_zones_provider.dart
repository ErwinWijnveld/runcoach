import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/auth/models/derived_zones.dart';

part 'onboarding_derived_zones_provider.g.dart';

/// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
/// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
///
/// Connect-health sets it via `.notifier.set(...)`; zones-screen reads it
/// on mount to populate source-aware subtitle copy (e.g. "Based on your
/// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
/// derive call failed silently) — the zones screen falls back to generic
/// copy based on `user.heartRateZonesSource`.
@Riverpod(keepAlive: true)
class OnboardingDerivedZones extends _$OnboardingDerivedZones {
  @override
  DerivedZones? build() => null;

  void set(DerivedZones? value) => state = value;
}
