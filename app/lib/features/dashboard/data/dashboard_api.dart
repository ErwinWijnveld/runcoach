import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';

part 'dashboard_api.g.dart';

@RestApi()
abstract class DashboardApi {
  factory DashboardApi(Dio dio) = _DashboardApi;

  @GET('/dashboard')
  Future<DashboardData> getDashboard();
}

@riverpod
DashboardApi dashboardApi(Ref ref) => DashboardApi(ref.watch(dioProvider));
