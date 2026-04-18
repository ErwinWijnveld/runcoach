import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/auth_interceptor.dart';
import 'package:app/core/storage/token_storage.dart';

part 'dio_client.g.dart';

// Release builds pass --dart-define=API_BASE_URL=https://runcoach.free.laravel.cloud/api/v1
// (see scripts/build-ios.sh). Local `flutter run` falls back to the LAN IP so
// physical iPhones can reach the Mac's `php artisan serve --host=0.0.0.0`.
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.178.31:8000/api/v1',
);

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(tokenStorage));

  return dio;
}
