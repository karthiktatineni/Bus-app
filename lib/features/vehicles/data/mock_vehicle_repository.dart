import '../../../core/errors/app_exception.dart';
import '../../../mock/mock_data.dart';
import '../../../mock/mock_delay.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_repository.dart';

class MockVehicleRepository implements VehicleRepository {
  final List<Vehicle> _vehicles = MockData.generateVehicles();

  @override
  Future<List<Vehicle>> list() async {
    await MockDelay.simulate();
    return List.unmodifiable(_vehicles);
  }

  @override
  Stream<List<Vehicle>> watch() async* {
    yield await list();
  }

  @override
  Future<Vehicle> get(String id) async {
    // Deliberate failing path
    if (id == 'fail-id' || id == 'veh-error') {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated vehicle retrieval failure.');
    }

    await MockDelay.simulate();
    return _vehicles.firstWhere(
      (v) => v.id == id,
      orElse: () => throw NotFoundException('Vehicle with ID $id not found.'),
    );
  }

  @override
  Future<Vehicle> create(Vehicle v) async {
    if (v.registrationNo.toUpperCase().contains('FAIL')) {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated vehicle creation failure.');
    }

    await MockDelay.simulate();
    _vehicles.add(v);
    return v;
  }

  @override
  Future<Vehicle> update(Vehicle v) async {
    if (v.id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated vehicle update failure.');
    }

    await MockDelay.simulate();
    final index = _vehicles.indexWhere((item) => item.id == v.id);
    if (index == -1) {
      throw NotFoundException('Vehicle with ID ${v.id} not found.');
    }
    _vehicles[index] = v;
    return v;
  }

  @override
  Future<void> delete(String id) async {
    if (id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true,
          failureMessage: 'Simulated vehicle deletion failure.');
    }

    await MockDelay.simulate();
    final index = _vehicles.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw NotFoundException('Vehicle with ID $id not found.');
    }
    _vehicles.removeAt(index);
  }

  @override
  Future<void> deletePhoto(String vehicleId, String photoUrl) async {
    await MockDelay.simulate();
    final index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index == -1) {
      throw NotFoundException('Vehicle with ID $vehicleId not found.');
    }
    final vehicle = _vehicles[index];
    _vehicles[index] = vehicle.copyWith(
      photos: vehicle.photos.where((photo) => photo != photoUrl).toList(),
    );
  }

  @override
  Future<void> addPhoto(String vehicleId, String filePath) async {
    await MockDelay.simulate();
    final index = _vehicles.indexWhere((vehicle) => vehicle.id == vehicleId);
    if (index == -1) {
      throw NotFoundException('Vehicle with ID $vehicleId not found.');
    }
    _vehicles[index] = _vehicles[index].copyWith(
      photos: [..._vehicles[index].photos, filePath],
    );
  }
}
