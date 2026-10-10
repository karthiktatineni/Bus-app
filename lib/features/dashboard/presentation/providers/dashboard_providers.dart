import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/models/dashboard_data.dart';
import '../../data/repositories/mock_dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  // Replace with RealDashboardRepository when backend is ready
  return MockDashboardRepository();
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardData();
});
