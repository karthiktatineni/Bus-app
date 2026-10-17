class MaintenanceTask {
  final String id;
  final String vehicleId;
  final String title;
  final DateTime? dueDate;
  final int? dueKm;
  final bool isDone;
  final String? scheduleId;
  final DateTime? completedAt;
  final String? completedBy;
  final String? serviceRecordId;

  const MaintenanceTask({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.dueDate,
    this.dueKm,
    this.isDone = false,
    this.scheduleId,
    this.completedAt,
    this.completedBy,
    this.serviceRecordId,
  });

  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return due.isBefore(todayDate);
  }

  MaintenanceTask copyWith({
    String? id,
    String? vehicleId,
    String? title,
    DateTime? dueDate,
    int? dueKm,
    bool? isDone,
    String? scheduleId,
    DateTime? completedAt,
    String? completedBy,
    String? serviceRecordId,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      dueKm: dueKm ?? this.dueKm,
      isDone: isDone ?? this.isDone,
      scheduleId: scheduleId ?? this.scheduleId,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      serviceRecordId: serviceRecordId ?? this.serviceRecordId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'dueKm': dueKm,
      'isDone': isDone,
      'scheduleId': scheduleId,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'serviceRecordId': serviceRecordId,
    };
  }

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      title: json['title'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueKm: json['dueKm'] as int?,
      isDone: json['isDone'] as bool? ?? false,
      scheduleId: json['scheduleId'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completedBy: json['completedBy'] as String?,
      serviceRecordId: json['serviceRecordId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehicleId == other.vehicleId &&
          title == other.title &&
          dueDate == other.dueDate &&
          dueKm == other.dueKm &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, vehicleId, title, dueDate, dueKm, isDone);
}
