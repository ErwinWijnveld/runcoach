import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/schedule/models/training_result.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

part 'celebration_provider.g.dart';

/// `shared_preferences` key tracking the highest wearable_activity.id
/// we've already celebrated. Used as `since_activity_id` on the backend
/// query so each run only gets one popup.
const _kLastCelebratedKey = 'last_celebrated_activity_id_v1';

@Riverpod(keepAlive: true)
class Celebration extends _$Celebration {
  @override
  Future<TrainingResult?> build() async {
    return findCelebratableRun();
  }

  /// Hit the backend endpoint with the locally-tracked watermark.
  /// Returns the TrainingResult (with wearable_activity nested) or null
  /// when nothing qualifies.
  Future<TrainingResult?> findCelebratableRun() async {
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt(_kLastCelebratedKey) ?? 0;

    final api = ref.read(wearableApiProvider);
    try {
      // wearableApi.getCelebratableRun adds the `since_activity_id`
      // query param so the backend filters server-side.
      final response =
          await api.getCelebratableRun(since == 0 ? null : since);
      final data = (response as Map<String, dynamic>)['data'];
      if (data == null) return null;
      return TrainingResult.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      // Soft-fail: not worth blocking app boot for a polish feature.
      return null;
    }
  }

  /// Mark a run as celebrated so it won't fire the popup again. Caller
  /// passes the wearable_activity id (NOT the training_result id).
  Future<void> markCelebrated(int wearableActivityId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kLastCelebratedKey) ?? 0;
    if (wearableActivityId > current) {
      await prefs.setInt(_kLastCelebratedKey, wearableActivityId);
    }
    // Invalidate so next read returns null (or the next eligible run).
    state = const AsyncData(null);
  }
}
