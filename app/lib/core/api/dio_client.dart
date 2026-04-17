import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/auth_interceptor.dart';
import 'package:app/core/storage/token_storage.dart';

part 'dio_client.g.dart';

// For iOS physical device: Mac's local IP (find with `ipconfig getifaddr en0`).
// For simulator/web: use localhost.
const String baseUrl = 'http://192.168.2.104:8000/api/v1';
// const String baseUrl = 'http://localhost:8000/api/v1';

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
