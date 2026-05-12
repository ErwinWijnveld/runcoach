import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/api/locale_interceptor.dart';
import 'package:app/core/i18n/current_locale.dart';

void main() {
  setUp(() {
    currentAppLocaleTag = 'en';
  });

  test('adds Accept-Language header matching currentAppLocaleTag', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(LocaleInterceptor());

    // Reject the request after capturing headers so no network call is made.
    String? captured;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        captured = options.headers['Accept-Language'] as String?;
        handler.reject(
          DioException(requestOptions: options, message: 'abort'),
        );
      },
    ));

    currentAppLocaleTag = 'nl';
    try {
      await dio.get<dynamic>('/ping');
    } on DioException {
      // expected
    }

    expect(captured, 'nl');
  });

  test('reads the latest tag value at request time, not at construct time',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(LocaleInterceptor());

    String? captured;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        captured = options.headers['Accept-Language'] as String?;
        handler.reject(
          DioException(requestOptions: options, message: 'abort'),
        );
      },
    ));

    currentAppLocaleTag = 'en';
    try {
      await dio.get<dynamic>('/first');
    } on DioException {
      // expected
    }
    expect(captured, 'en');

    currentAppLocaleTag = 'nl';
    try {
      await dio.get<dynamic>('/second');
    } on DioException {
      // expected
    }
    expect(captured, 'nl');
  });
}
