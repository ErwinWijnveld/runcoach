// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _DashboardApi implements DashboardApi {
  _DashboardApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<DashboardData> getDashboard() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<DashboardData>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/dashboard',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late DashboardData _value;
    try {
      _value = DashboardData.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
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

@ProviderFor(dashboardApi)
final dashboardApiProvider = DashboardApiProvider._();

final class DashboardApiProvider
    extends $FunctionalProvider<DashboardApi, DashboardApi, DashboardApi>
    with $Provider<DashboardApi> {
  DashboardApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardApiHash();

  @$internal
  @override
  $ProviderElement<DashboardApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardApi create(Ref ref) {
    return dashboardApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardApi>(value),
    );
  }
}

String _$dashboardApiHash() => r'7282212568c0a0ade9aa2f2117c02ebf71054da6';
