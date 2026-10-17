import '../../../core/widgets/status_chip.dart';

enum VehicleStatus {
  active('Active'),
  dueSoon('Due Soon'),
  overdue('Overdue'),
  inWorkshop('In Workshop');

  final String label;
  const VehicleStatus(this.label);

  /// Canonical value used by the Supabase vehicles.status constraint.
  String get dbValue => switch (this) {
        VehicleStatus.active => 'active',
        VehicleStatus.dueSoon => 'due_soon',
        VehicleStatus.overdue => 'overdue',
        VehicleStatus.inWorkshop => 'in_workshop',
      };

  /// Accept both Dart enum names and the database's snake_case values.
  static VehicleStatus fromStorage(Object? value) {
    final normalized = value?.toString().replaceAll('_', '').toLowerCase();
    return switch (normalized) {
      'duesoon' => VehicleStatus.dueSoon,
      'inworkshop' => VehicleStatus.inWorkshop,
      'overdue' => VehicleStatus.overdue,
      'active' => VehicleStatus.active,
      _ => VehicleStatus.active,
    };
  }

  ChipStatus get chipStatus {
    switch (this) {
      case VehicleStatus.active:
        return ChipStatus.operational;
      case VehicleStatus.dueSoon:
        return ChipStatus.warning;
      case VehicleStatus.overdue:
        return ChipStatus.danger;
      case VehicleStatus.inWorkshop:
        return ChipStatus.info;
    }
  }
}
