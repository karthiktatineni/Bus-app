import 'vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> list();
  Future<Vehicle> get(String id);
  Future<Vehicle> create(Vehicle v);
  Future<Vehicle> update(Vehicle v);
  Future<void> delete(String id);
}
