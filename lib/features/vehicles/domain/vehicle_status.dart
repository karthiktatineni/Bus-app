import '../../../core/widgets/status_chip.dart';

enum VehicleStatus {
  active('Active'),
  dueSoon('Due Soon'),
  overdue('Overdue'),
  inWorkshop('In Workshop');

  final String label;
  const VehicleStatus(this.label);

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
