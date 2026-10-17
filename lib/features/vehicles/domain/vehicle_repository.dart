import 'vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> list();
  Stream<List<Vehicle>> watch();
  Future<Vehicle> get(String id);
  Future<Vehicle> create(Vehicle v);
  Future<Vehicle> update(Vehicle v);
  Future<void> delete(String id);
  Future<void> deletePhoto(String vehicleId, String photoUrl);
  Future<void> addPhoto(String vehicleId, String filePath);
}
