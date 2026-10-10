import 'service_record.dart';
import 'maintenance_task.dart';

abstract class ServiceRepository {
  Future<List<ServiceRecord>> listAll({String? vehicleId});
  Future<ServiceRecord> get(String id);
  Future<ServiceRecord> create(ServiceRecord r);
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14});
  Future<void> setTaskDone(String taskId, bool done);
}
