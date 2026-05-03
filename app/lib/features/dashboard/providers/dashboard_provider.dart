import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/dashboard/data/dashboard_api.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';
import 'package:app/features/schedule/providers/plan_version_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardData> dashboard(Ref ref) async {
  ref.watch(planVersionProvider);
  final api = ref.watch(dashboardApiProvider);
  return api.getDashboard();
}
