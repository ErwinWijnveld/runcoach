import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/races/data/race_api.dart';
import 'package:app/features/races/models/race.dart';

part 'race_provider.g.dart';

@riverpod
Future<List<Race>> races(Ref ref) async {
  final api = ref.watch(raceApiProvider);
  final data = await api.getRaces();
  final list = data['data'] as List;
  return list.map((e) => Race.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<Race> raceDetail(Ref ref, int id) async {
  final api = ref.watch(raceApiProvider);
  final data = await api.getRace(id);
  return Race.fromJson(data['data'] as Map<String, dynamic>);
}

@riverpod
class RaceActions extends _$RaceActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createRace({
    required String name,
    required String distance,
    required String raceDate,
    int? goalTimeSeconds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(raceApiProvider);
      await api.createRace({
        'name': name,
        'distance': distance,
        'race_date': raceDate,
        'goal_time_seconds': ?goalTimeSeconds,
      });
      ref.invalidate(racesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRace(int id) async {
    final api = ref.read(raceApiProvider);
    await api.deleteRace(id);
    ref.invalidate(racesProvider);
  }
}
