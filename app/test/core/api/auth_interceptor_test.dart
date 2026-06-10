import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/api/auth_interceptor.dart';
import 'package:app/core/storage/token_storage.dart';

/// Storage whose read blows up — models a locked/unavailable keychain (or
/// the MissingPluginException every widget test environment produces).
class _ThrowingTokenStorage extends TokenStorage {
  _ThrowingTokenStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getToken() async =>
      throw MissingPluginException('no keychain in tests');
}

class _FixedTokenStorage extends TokenStorage {
  _FixedTokenStorage(this._token) : super(const FlutterSecureStorage());

  final String? _token;

  @override
  Future<String?> getToken() async => _token;
}

void main() {
  test('storage failure rejects the request with a catchable DioException',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(AuthInterceptor(_ThrowingTokenStorage()));

    // Without the guard, the async-void onRequest leaks the exception into
    // the zone (uncatchable) and never calls handler.next → the request
    // hangs forever. Race against a timeout to detect the hang fast.
    final result = await Future.any<Object?>([
      dio
          .get<dynamic>('/ping')
          .then<Object?>((_) => 'completed', onError: (Object e) => e),
      Future<Object?>.delayed(const Duration(seconds: 2), () => 'hung'),
    ]);

    expect(result, isA<DioException>());
  });

  test('attaches bearer token from storage', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(AuthInterceptor(_FixedTokenStorage('tok-123')));

    // Reject after capturing headers so no network call is made.
    String? auth;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        auth = options.headers['Authorization'] as String?;
        handler.reject(
          DioException(requestOptions: options, message: 'abort'),
        );
      },
    ));

    try {
      await dio.get<dynamic>('/ping');
    } on DioException {
      // expected
    }

    expect(auth, 'Bearer tok-123');
  });
}
