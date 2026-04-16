import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';

part 'onboarding_provider.g.dart';

@riverpod
Future<String> onboardingConversationId(Ref ref) async {
  final api = ref.watch(onboardingApiProvider);
  final result = await api.start();
  return (result as Map<String, dynamic>)['conversation_id'] as String;
}
