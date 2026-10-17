import 'service_record.dart';
import 'maintenance_task.dart';
import 'service_schedule.dart';

abstract class ServiceRepository {
  Future<List<ServiceRecord>> listAll({String? vehicleId});
  Future<ServiceRecord> get(String id);
  Future<ServiceRecord> create(ServiceRecord r);
  Future<ServiceRecord> update(ServiceRecord r);
  Future<void> delete(String id);
  Future<void> deletePhoto(String serviceId, String photoId);
  Future<void> addPhoto(String serviceId, String filePath, PhotoType type);
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14});
  Future<MaintenanceTask> createTask(MaintenanceTask task);
  Future<MaintenanceTask?> taskForService(String serviceRecordId);
  Future<MaintenanceTask> updateTask(MaintenanceTask task);
  Future<void> setTaskDone(String taskId, bool done);
  Future<List<ServiceSchedule>> listSchedules({String? vehicleId});
  Future<ServiceSchedule> createSchedule(ServiceSchedule s);
  Future<ServiceSchedule> updateSchedule(ServiceSchedule s);
}
