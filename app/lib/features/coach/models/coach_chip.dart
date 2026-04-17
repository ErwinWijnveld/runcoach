import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_chip.freezed.dart';
part 'coach_chip.g.dart';

@freezed
sealed class CoachChip with _$CoachChip {
  const factory CoachChip({
    required String label,
    required String value,
  }) = _CoachChip;

  factory CoachChip.fromJson(Map<String, dynamic> json) =>
      _$CoachChipFromJson(json);
}
