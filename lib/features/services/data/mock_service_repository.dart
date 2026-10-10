import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../../../mock/mock_data.dart';
import '../../../mock/mock_delay.dart';
import '../domain/service_record.dart';
import '../domain/maintenance_task.dart';
import '../domain/service_repository.dart';

class MockServiceRepository implements ServiceRepository {
  final List<ServiceRecord> _services = MockData.generateServiceRecords();
  final List<MaintenanceTask> _tasks = MockData.generateTasks();

  @override
  Future<List<ServiceRecord>> listAll({String? vehicleId}) async {
    await MockDelay.simulate();
    if (vehicleId != null) {
      return _services.where((s) => s.vehicleId == vehicleId).toList();
    }
    return List.unmodifiable(_services);
  }

  @override
  Future<ServiceRecord> get(String id) async {
    // Deliberate failing path
    if (id == 'fail-id' || id == 'srv-error') {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated service record retrieval error.');
    }

    await MockDelay.simulate();
    return _services.firstWhere(
      (s) => s.id == id,
      orElse: () => throw NotFoundException('Service record with ID $id not found.'),
    );
  }

  @override
  Future<ServiceRecord> create(ServiceRecord r) async {
    if (r.workshop.contains('FAIL')) {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated service record creation error.');
    }

    await MockDelay.simulate();
    _services.insert(0, r);
    return r;
  }

  @override
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14}) async {
    await MockDelay.simulate();
    return _tasks.where((t) {
      if (t.isDone) return false;
      if (t.dueDate == null) return true;
      return AppDateUtils.isDueSoon(t.dueDate!, withinDays: withinDays) ||
          AppDateUtils.isOverdue(t.dueDate!);
    }).toList();
  }

  @override
  Future<void> setTaskDone(String taskId, bool done) async {
    if (taskId == 'fail-id') {
      await MockDelay.simulate(shouldFail: true, failureMessage: 'Simulated task status update error.');
    }

    await MockDelay.simulate();
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw NotFoundException('Task with ID $taskId not found.');
    }
    _tasks[index] = _tasks[index].copyWith(
      isDone: done,
      completedAt: done ? DateTime.now() : null,
      completedBy: done ? 'usr-001' : null,
    );
  }
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return MockServiceRepository();
});
