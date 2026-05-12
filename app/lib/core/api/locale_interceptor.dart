import 'package:dio/dio.dart';

import 'package:app/core/i18n/current_locale.dart';

/// Adds the `Accept-Language` header to every outgoing request, using
/// the BCP-47 tag held in [currentAppLocaleTag]. The interceptor reads
/// the global on each request, so locale overrides propagate to
/// in-flight Dio without needing to rebuild it.
///
/// Server side: the `SetLocale` middleware reads this header and sets
/// `App::setLocale()` per request, which makes `__()` lookups resolve
/// validation messages + agent output in the runner's language.
class LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = currentAppLocaleTag;
    super.onRequest(options, handler);
  }
}
