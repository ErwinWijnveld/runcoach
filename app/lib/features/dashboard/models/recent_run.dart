import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/wearable_activity_summary.dart';

part 'recent_run.freezed.dart';
part 'recent_run.g.dart';

/// One entry in the dashboard's "Recent runs" list: the wearable run plus
/// its training-day linkage. `trainingDayId` null means off-plan (render the
/// blue plus → link sheet); `complianceScore` (0–10) is null until the run
/// has been matched and scored.
@freezed
sealed class RecentRun with _$RecentRun {
  const factory RecentRun({
    required WearableActivitySummary run,
    @JsonKey(name: 'training_day_id', fromJson: toIntOrNull) int? trainingDayId,
    @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull)
    double? complianceScore,
  }) = _RecentRun;

  factory RecentRun.fromJson(Map<String, dynamic> json) =>
      _$RecentRunFromJson(json);
}
