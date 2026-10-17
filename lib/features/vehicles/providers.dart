import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/vehicle_repository.dart';
import 'data/supabase_vehicle_repository.dart';
import '../../core/services/supabase_service.dart';

export 'domain/vehicle.dart';
export 'domain/vehicle_document.dart';
export 'domain/vehicle_photo.dart';
export 'domain/vehicle_status.dart';
export 'domain/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return SupabaseVehicleRepository(ref.watch(supabaseClientProvider));
});
