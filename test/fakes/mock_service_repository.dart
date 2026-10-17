import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/core/utils/date_utils.dart';
import 'package:bus_app/features/services/domain/service_record.dart';
import 'package:bus_app/features/services/domain/maintenance_task.dart';
import 'package:bus_app/features/services/domain/service_schedule.dart';
import 'package:bus_app/features/services/domain/service_repository.dart';
import 'mock_data.dart';
import 'mock_delay.dart';

class MockServiceRepository implements ServiceRepository {
  final List<ServiceRecord> _services = MockData.generateServiceRecords();
  final List<ServiceSchedule> _schedules = MockData.generateSchedules();
  late final List<MaintenanceTask> _tasks;

  MockServiceRepository() {
    _tasks = MockData.generateTasks(schedules: _schedules);
  }

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
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated service record retrieval error.');
    }

    await MockDelay.simulate();
    return _services.firstWhere(
      (s) => s.id == id,
      orElse: () =>
          throw NotFoundException('Service record with ID $id not found.'),
    );
  }

  @override
  Future<ServiceRecord> create(ServiceRecord r) async {
    if (r.workshop.contains('FAIL')) {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated service record creation error.');
    }

    await MockDelay.simulate();
    _services.insert(0, r);

    // If this service was for a schedule, advance the schedule's cycle
    final scheduleIndex =
        _schedules.indexWhere((s) => s.vehicleId == r.vehicleId);
    if (scheduleIndex != -1) {
      _schedules[scheduleIndex] = _schedules[scheduleIndex].cycleCompleted(
        completedDate: r.date,
        completedKm: r.odometerKm,
      );
    }

    return r;
  }

  @override
  Future<ServiceRecord> update(ServiceRecord r) async {
    await MockDelay.simulate();
    final index = _services.indexWhere((service) => service.id == r.id);
    if (index < 0) {
      throw NotFoundException('Service record with ID ${r.id} not found.');
    }
    _services[index] = r;
    return r;
  }

  @override
  Future<void> delete(String id) async {
    await MockDelay.simulate();
    final index = _services.indexWhere((service) => service.id == id);
    if (index == -1) {
      throw NotFoundException('Service record with ID $id not found.');
    }
    _services.removeAt(index);
  }

  @override
  Future<void> deletePhoto(String serviceId, String photoId) async {
    await MockDelay.simulate();
    final index = _services.indexWhere((service) => service.id == serviceId);
    if (index == -1) {
      throw NotFoundException('Service record with ID $serviceId not found.');
    }
    final record = _services[index];
    _services[index] = record.copyWith(
      photos: record.photos.where((photo) => photo.id != photoId).toList(),
    );
  }

  @override
  Future<void> addPhoto(
      String serviceId, String filePath, PhotoType type) async {
    await MockDelay.simulate();
    final index = _services.indexWhere((service) => service.id == serviceId);
    if (index == -1) {
      throw NotFoundException('Service record with ID $serviceId not found.');
    }
    final record = _services[index];
    _services[index] = record.copyWith(
      photos: [
        ...record.photos,
        ServicePhoto(
          id: 'photo_${DateTime.now().microsecondsSinceEpoch}',
          url: filePath,
          type: type,
        ),
      ],
    );
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
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    await MockDelay.simulate();
    _tasks.add(task);
    return task;
  }

  @override
  Future<MaintenanceTask?> taskForService(String serviceRecordId) async {
    await MockDelay.simulate();
    for (final task in _tasks) {
      if (task.serviceRecordId == serviceRecordId) return task;
    }
    return null;
  }

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async {
    await MockDelay.simulate();
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) {
      throw NotFoundException('Task with ID ${task.id} not found.');
    }
    _tasks[index] = task;
    return task;
  }

  @override
  Future<void> setTaskDone(String taskId, bool done) async {
    if (taskId == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated task status update error.');
    }

    await MockDelay.simulate();
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw NotFoundException('Task with ID $taskId not found.');
    }

    final task = _tasks[index];
    _tasks[index] = task.copyWith(
      isDone: done,
      completedAt: done ? DateTime.now() : null,
      completedBy: done ? 'usr-001' : null,
    );

    // Advance schedule if task was linked to a schedule
    if (done && task.scheduleId != null) {
      final scheduleIndex =
          _schedules.indexWhere((s) => s.id == task.scheduleId);
      if (scheduleIndex != -1) {
        final currentSchedule = _schedules[scheduleIndex];
        _schedules[scheduleIndex] = currentSchedule.cycleCompleted(
          completedDate: DateTime.now(),
          completedKm: currentSchedule.nextDueKm,
        );
      }
    }
  }

  @override
  Future<List<ServiceSchedule>> listSchedules({String? vehicleId}) async {
    await MockDelay.simulate();
    if (vehicleId != null) {
      return _schedules.where((s) => s.vehicleId == vehicleId).toList();
    }
    return List.unmodifiable(_schedules);
  }

  @override
  Future<ServiceSchedule> createSchedule(ServiceSchedule s) async {
    await MockDelay.simulate();
    _schedules.add(s);
    return s;
  }

  @override
  Future<ServiceSchedule> updateSchedule(ServiceSchedule s) async {
    await MockDelay.simulate();
    final index = _schedules.indexWhere((item) => item.id == s.id);
    if (index == -1) {
      throw NotFoundException('Schedule with ID ${s.id} not found.');
    }
    _schedules[index] = s;
    return s;
  }
}
