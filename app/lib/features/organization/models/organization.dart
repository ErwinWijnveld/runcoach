import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization.freezed.dart';
part 'organization.g.dart';

@freezed
sealed class Organization with _$Organization {
  const factory Organization({
    required int id,
    required String name,
    required String slug,
    String? description,
    String? website,
    @JsonKey(name: 'logo_path') String? logoPath,
    @JsonKey(name: 'logo_url') String? logoUrl,
  }) = _Organization;

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
}
