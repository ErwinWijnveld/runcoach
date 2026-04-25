// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _OnboardingApi implements OnboardingApi {
  _OnboardingApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<dynamic> getProfile() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<dynamic>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/onboarding/profile',
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

@ProviderFor(onboardingApi)
final onboardingApiProvider = OnboardingApiProvider._();

final class OnboardingApiProvider
    extends $FunctionalProvider<OnboardingApi, OnboardingApi, OnboardingApi>
    with $Provider<OnboardingApi> {
  OnboardingApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingApiHash();

  @$internal
  @override
  $ProviderElement<OnboardingApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OnboardingApi create(Ref ref) {
    return onboardingApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingApi>(value),
    );
  }
}

String _$onboardingApiHash() => r'70e4a2d138b8c0db6686f88b1edbc6331304587e';

/// First call hits the inline Strava sync on the backend (30-90s). Bypasses
/// Retrofit so we can override Dio's 30s `receiveTimeout`. After the user has
/// activities cached, the call returns instantly.

@ProviderFor(getProfileCall)
final getProfileCallProvider = GetProfileCallProvider._();

/// First call hits the inline Strava sync on the backend (30-90s). Bypasses
/// Retrofit so we can override Dio's 30s `receiveTimeout`. After the user has
/// activities cached, the call returns instantly.

final class GetProfileCallProvider
    extends
        $FunctionalProvider<
          Future<Map<String, dynamic>> Function(),
          Future<Map<String, dynamic>> Function(),
          Future<Map<String, dynamic>> Function()
        >
    with $Provider<Future<Map<String, dynamic>> Function()> {
  /// First call hits the inline Strava sync on the backend (30-90s). Bypasses
  /// Retrofit so we can override Dio's 30s `receiveTimeout`. After the user has
  /// activities cached, the call returns instantly.
  GetProfileCallProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getProfileCallProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getProfileCallHash();

  @$internal
  @override
  $ProviderElement<Future<Map<String, dynamic>> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<Map<String, dynamic>> Function() create(Ref ref) {
    return getProfileCall(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<Map<String, dynamic>> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Future<Map<String, dynamic>> Function()>(value),
    );
  }
}

String _$getProfileCallHash() => r'43c6b7d6a77d46cea9c7fa1de69369daa66e97ff';

/// Enqueues plan generation. Returns the PlanGeneration row in queued state
/// (or the existing in-flight row, if there is one). The screen polls
/// [pollPlanGenerationCall] for status updates. The actual agent loop runs
/// in the queue worker (~60-110s) so this POST returns in <1s.

@ProviderFor(generatePlanCall)
final generatePlanCallProvider = GeneratePlanCallProvider._();

/// Enqueues plan generation. Returns the PlanGeneration row in queued state
/// (or the existing in-flight row, if there is one). The screen polls
/// [pollPlanGenerationCall] for status updates. The actual agent loop runs
/// in the queue worker (~60-110s) so this POST returns in <1s.

final class GeneratePlanCallProvider
    extends
        $FunctionalProvider<
          Future<PlanGeneration> Function(Map<String, dynamic> body),
          Future<PlanGeneration> Function(Map<String, dynamic> body),
          Future<PlanGeneration> Function(Map<String, dynamic> body)
        >
    with $Provider<Future<PlanGeneration> Function(Map<String, dynamic> body)> {
  /// Enqueues plan generation. Returns the PlanGeneration row in queued state
  /// (or the existing in-flight row, if there is one). The screen polls
  /// [pollPlanGenerationCall] for status updates. The actual agent loop runs
  /// in the queue worker (~60-110s) so this POST returns in <1s.
  GeneratePlanCallProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generatePlanCallProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generatePlanCallHash();

  @$internal
  @override
  $ProviderElement<Future<PlanGeneration> Function(Map<String, dynamic> body)>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Future<PlanGeneration> Function(Map<String, dynamic> body) create(Ref ref) {
    return generatePlanCall(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Future<PlanGeneration> Function(Map<String, dynamic> body) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            Future<PlanGeneration> Function(Map<String, dynamic> body)
          >(value),
    );
  }
}

String _$generatePlanCallHash() => r'0c33ea4c1a4ef5a5aa55bb3a9a9e12b7a35d9c96';

/// Polls the latest user-actionable plan generation. Returns null when the
/// server responds 204 (nothing pending). The screen interprets null
/// mid-flight as an error condition (the row was unexpectedly cleared).

@ProviderFor(pollPlanGenerationCall)
final pollPlanGenerationCallProvider = PollPlanGenerationCallProvider._();

/// Polls the latest user-actionable plan generation. Returns null when the
/// server responds 204 (nothing pending). The screen interprets null
/// mid-flight as an error condition (the row was unexpectedly cleared).

final class PollPlanGenerationCallProvider
    extends
        $FunctionalProvider<
          Future<PlanGeneration?> Function(),
          Future<PlanGeneration?> Function(),
          Future<PlanGeneration?> Function()
        >
    with $Provider<Future<PlanGeneration?> Function()> {
  /// Polls the latest user-actionable plan generation. Returns null when the
  /// server responds 204 (nothing pending). The screen interprets null
  /// mid-flight as an error condition (the row was unexpectedly cleared).
  PollPlanGenerationCallProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pollPlanGenerationCallProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pollPlanGenerationCallHash();

  @$internal
  @override
  $ProviderElement<Future<PlanGeneration?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<PlanGeneration?> Function() create(Ref ref) {
    return pollPlanGenerationCall(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<PlanGeneration?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<PlanGeneration?> Function()>(
        value,
      ),
    );
  }
}

String _$pollPlanGenerationCallHash() =>
    r'8a2a349b9f07a26ec40d3971e02bed90a5b6759f';
