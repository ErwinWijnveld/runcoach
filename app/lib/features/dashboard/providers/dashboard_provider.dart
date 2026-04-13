import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/dashboard/data/dashboard_api.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardData> dashboard(Ref ref) async {
  final api = ref.watch(dashboardApiProvider);
  return api.getDashboard();
}
