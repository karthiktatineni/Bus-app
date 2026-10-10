import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/vehicle_repository.dart';
import 'data/mock_vehicle_repository.dart';

export 'domain/vehicle.dart';
export 'domain/vehicle_document.dart';
export 'domain/vehicle_photo.dart';
export 'domain/vehicle_status.dart';
export 'domain/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return MockVehicleRepository();
});
