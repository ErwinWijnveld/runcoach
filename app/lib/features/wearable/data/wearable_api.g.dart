// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wearable_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _WearableApi implements WearableApi {
  _WearableApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<dynamic> ingest(Map<String, dynamic> body) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _options = _setStreamType<dynamic>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/wearable/activities',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    return _value;
  }

  @override
  Future<dynamic> list() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<dynamic>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/wearable/activities',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    return _value;
  }

  @override
  Future<dynamic> analysisStatus(int id) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<dynamic>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/wearable/activities/${id}/analysis',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    return _value;
  }

  @override
  Future<dynamic> ingestPersonalRecords(Map<String, dynamic> body) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body);
    final _options = _setStreamType<dynamic>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/wearable/personal-records',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wearableApi)
final wearableApiProvider = WearableApiProvider._();

final class WearableApiProvider
    extends $FunctionalProvider<WearableApi, WearableApi, WearableApi>
    with $Provider<WearableApi> {
  WearableApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wearableApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wearableApiHash();

  @$internal
  @override
  $ProviderElement<WearableApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WearableApi create(Ref ref) {
    return wearableApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WearableApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WearableApi>(value),
    );
  }
}

String _$wearableApiHash() => r'd03e142ba2213cfc532a8df1ec3a7aed5cad5dc7';

@ProviderFor(healthKitService)
final healthKitServiceProvider = HealthKitServiceProvider._();

final class HealthKitServiceProvider
    extends
        $FunctionalProvider<
          HealthKitService,
          HealthKitService,
          HealthKitService
        >
    with $Provider<HealthKitService> {
  HealthKitServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthKitServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthKitServiceHash();

  @$internal
  @override
  $ProviderElement<HealthKitService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthKitService create(Ref ref) {
    return healthKitService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthKitService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthKitService>(value),
    );
  }
}

String _$healthKitServiceHash() => r'13d4817577f6dc7109717adb93acb90a9e672016';

/// On-demand HealthKit PR lookup for a single distance, cached per-distance
/// by Riverpod's family auto-caching. Used by the onboarding form's goal
/// time + current-PR steps so the field pre-fills the moment the user
/// picks a distance — including custom "Other → 26km" picks the standard
/// connect-health prefetch doesn't cover.
///
/// Returns the raw map from the MethodChannel (durationSeconds,
/// distanceMeters, date, sourceActivityId) or null when no qualifying
/// workout exists. The form converts to a parsed seconds value itself.

@ProviderFor(personalRecordForDistance)
final personalRecordForDistanceProvider = PersonalRecordForDistanceFamily._();

/// On-demand HealthKit PR lookup for a single distance, cached per-distance
/// by Riverpod's family auto-caching. Used by the onboarding form's goal
/// time + current-PR steps so the field pre-fills the moment the user
/// picks a distance — including custom "Other → 26km" picks the standard
/// connect-health prefetch doesn't cover.
///
/// Returns the raw map from the MethodChannel (durationSeconds,
/// distanceMeters, date, sourceActivityId) or null when no qualifying
/// workout exists. The form converts to a parsed seconds value itself.

final class PersonalRecordForDistanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  /// On-demand HealthKit PR lookup for a single distance, cached per-distance
  /// by Riverpod's family auto-caching. Used by the onboarding form's goal
  /// time + current-PR steps so the field pre-fills the moment the user
  /// picks a distance — including custom "Other → 26km" picks the standard
  /// connect-health prefetch doesn't cover.
  ///
  /// Returns the raw map from the MethodChannel (durationSeconds,
  /// distanceMeters, date, sourceActivityId) or null when no qualifying
  /// workout exists. The form converts to a parsed seconds value itself.
  PersonalRecordForDistanceProvider._({
    required PersonalRecordForDistanceFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'personalRecordForDistanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalRecordForDistanceHash();

  @override
  String toString() {
    return r'personalRecordForDistanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as int;
    return personalRecordForDistance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalRecordForDistanceProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalRecordForDistanceHash() =>
    r'8132c0408cd99692bd9fab6f766a5d8425e3287a';

/// On-demand HealthKit PR lookup for a single distance, cached per-distance
/// by Riverpod's family auto-caching. Used by the onboarding form's goal
/// time + current-PR steps so the field pre-fills the moment the user
/// picks a distance — including custom "Other → 26km" picks the standard
/// connect-health prefetch doesn't cover.
///
/// Returns the raw map from the MethodChannel (durationSeconds,
/// distanceMeters, date, sourceActivityId) or null when no qualifying
/// workout exists. The form converts to a parsed seconds value itself.

final class PersonalRecordForDistanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, int> {
  PersonalRecordForDistanceFamily._()
    : super(
        retry: null,
        name: r'personalRecordForDistanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// On-demand HealthKit PR lookup for a single distance, cached per-distance
  /// by Riverpod's family auto-caching. Used by the onboarding form's goal
  /// time + current-PR steps so the field pre-fills the moment the user
  /// picks a distance — including custom "Other → 26km" picks the standard
  /// connect-health prefetch doesn't cover.
  ///
  /// Returns the raw map from the MethodChannel (durationSeconds,
  /// distanceMeters, date, sourceActivityId) or null when no qualifying
  /// workout exists. The form converts to a parsed seconds value itself.

  PersonalRecordForDistanceProvider call(int distanceMeters) =>
      PersonalRecordForDistanceProvider._(argument: distanceMeters, from: this);

  @override
  String toString() => r'personalRecordForDistanceProvider';
}
