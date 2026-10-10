import 'maintenance_task.dart';

class ServiceSchedule {
  final String id;
  final String vehicleId;
  final String taskName;
  final int intervalKm;
  final int intervalMonths;
  final DateTime lastDoneDate;
  final int lastDoneKm;

  const ServiceSchedule({
    required this.id,
    required this.vehicleId,
    required this.taskName,
    required this.intervalKm,
    required this.intervalMonths,
    required this.lastDoneDate,
    required this.lastDoneKm,
  });

  /// Next due date calculated by adding intervalMonths to lastDoneDate
  DateTime get nextDueDate {
    return DateTime(
      lastDoneDate.year,
      lastDoneDate.month + intervalMonths,
      lastDoneDate.day,
    );
  }

  /// Next due odometer km
  int get nextDueKm => lastDoneKm + intervalKm;

  /// Checks if this schedule is due given the vehicle's current odometer reading and reference date
  bool isDue({required int currentOdometerKm, DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final isDueByKm = currentOdometerKm >= nextDueKm;
    final isDueByDate = now.isAfter(nextDueDate) || now.isAtSameMomentAs(nextDueDate);
    return isDueByKm || isDueByDate;
  }

  /// Checks if this schedule is overdue
  bool isOverdue({required int currentOdometerKm, DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    return currentOdometerKm > nextDueKm || now.isAfter(nextDueDate);
  }

  /// Calculates days remaining until the date threshold (negative if overdue)
  int daysRemaining({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final target = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    final ref = DateTime(now.year, now.month, now.day);
    return target.difference(ref).inDays;
  }

  /// Calculates km remaining until the km threshold (negative if overdue)
  int kmRemaining(int currentOdometerKm) {
    return nextDueKm - currentOdometerKm;
  }

  /// Generates a MaintenanceTask from this schedule
  MaintenanceTask generateTask({
    required String taskId,
    required int currentOdometerKm,
    DateTime? currentDate,
  }) {
    return MaintenanceTask(
      id: taskId,
      vehicleId: vehicleId,
      title: taskName,
      dueDate: nextDueDate,
      dueKm: nextDueKm,
      isDone: false,
      scheduleId: id,
    );
  }

  /// Returns a new ServiceSchedule updated when a service/task is completed, advancing the cycle
  ServiceSchedule cycleCompleted({
    required DateTime completedDate,
    required int completedKm,
  }) {
    return ServiceSchedule(
      id: id,
      vehicleId: vehicleId,
      taskName: taskName,
      intervalKm: intervalKm,
      intervalMonths: intervalMonths,
      lastDoneDate: completedDate,
      lastDoneKm: completedKm,
    );
  }

  ServiceSchedule copyWith({
    String? id,
    String? vehicleId,
    String? taskName,
    int? intervalKm,
    int? intervalMonths,
    DateTime? lastDoneDate,
    int? lastDoneKm,
  }) {
    return ServiceSchedule(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      taskName: taskName ?? this.taskName,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
      lastDoneKm: lastDoneKm ?? this.lastDoneKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'taskName': taskName,
      'intervalKm': intervalKm,
      'intervalMonths': intervalMonths,
      'lastDoneDate': lastDoneDate.toIso8601String(),
      'lastDoneKm': lastDoneKm,
    };
  }

  factory ServiceSchedule.fromJson(Map<String, dynamic> json) {
    return ServiceSchedule(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      taskName: json['taskName'] as String,
      intervalKm: json['intervalKm'] as int,
      intervalMonths: json['intervalMonths'] as int,
      lastDoneDate: DateTime.parse(json['lastDoneDate'] as String),
      lastDoneKm: json['lastDoneKm'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehicleId == other.vehicleId &&
          taskName == other.taskName &&
          intervalKm == other.intervalKm &&
          intervalMonths == other.intervalMonths &&
          lastDoneDate == other.lastDoneDate &&
          lastDoneKm == other.lastDoneKm;

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        taskName,
        intervalKm,
        intervalMonths,
        lastDoneDate,
        lastDoneKm,
      );
}
