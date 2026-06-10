import 'package:dio/dio.dart';
import 'package:app/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // This method is async-void: an uncaught throw after the first await
    // bypasses Dio's error pipeline (unhandled zone error) AND never calls
    // the handler, hanging the request forever. A storage failure must be
    // routed through handler.reject so callers get a catchable DioException.
    final String? token;
    try {
      token = await _tokenStorage.getToken();
    } catch (e) {
      handler.reject(DioException(requestOptions: options, error: e));
      return;
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await _tokenStorage.clearToken();
      } catch (_) {
        // Best-effort — same async-void escape hatch as onRequest; the 401
        // still propagates to the caller either way.
      }
    }
    handler.next(err);
  }
}
