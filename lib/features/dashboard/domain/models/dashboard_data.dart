class Vehicle {
  final String id;
  final String registration;
  final String make;
  final int year;
  final String status;
  final String nextMaintenance;
  final int odometerKm;

  Vehicle({
    required this.id,
    required this.registration,
    required this.make,
    required this.year,
    required this.status,
    required this.nextMaintenance,
    required this.odometerKm,
  });
}

class TodoItem {
  final String id;
  final String taskName;
  final String status;
  final String vehicleId;
  final String details;

  TodoItem({
    required this.id,
    required this.taskName,
    required this.status,
    required this.vehicleId,
    required this.details,
  });
}

class DashboardData {
  final int overdueCount;
  final int dueSoonCount;
  final int workshopCount;
  final List<TodoItem> todos;
  final List<Vehicle> upcomingVehicles;
  final List<Vehicle> allVehicles;

  DashboardData({
    required this.overdueCount,
    required this.dueSoonCount,
    required this.workshopCount,
    required this.todos,
    required this.upcomingVehicles,
    required this.allVehicles,
  });
}
