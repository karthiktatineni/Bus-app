import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/features/auth/domain/app_user.dart';
import '../fakes/mock_auth_repository.dart';
import 'package:bus_app/features/vehicles/domain/vehicle.dart';
import 'package:bus_app/features/vehicles/domain/vehicle_status.dart';
import '../fakes/mock_vehicle_repository.dart';
import '../fakes/mock_service_repository.dart';
import '../fakes/mock_bill_repository.dart';
import '../fakes/mock_ocr_service.dart';
import '../fakes/mock_user_repository.dart';
import '../fakes/mock_settings_repository.dart';
import '../fakes/mock_delay.dart';

void main() {
  setUpAll(() {
    MockDelay.enableDelays = false;
  });

  tearDownAll(() {
    MockDelay.enableDelays = true;
  });

  group('MockAuthRepository Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    test('sign in with valid credentials succeeds', () async {
      final user = await repo.signIn('karthik@fleetpulse.com', 'password123');
      expect(user.email, 'karthik@fleetpulse.com');
      expect(user.role, UserRole.admin);

      final current = await repo.getCurrentUser();
      expect(current?.id, user.id);
    });

    test('sign in with incorrect password throws UnauthorizedException',
        () async {
      expect(
        () => repo.signIn('karthik@fleetpulse.com', 'wrongpassword'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('failing path throws SimulationException', () async {
      expect(
        () => repo.signIn('fail@fleetpulse.com', 'password123'),
        throwsA(isA<SimulationException>()),
      );
    });
  });

  group('MockVehicleRepository Tests', () {
    late MockVehicleRepository repo;

    setUp(() {
      repo = MockVehicleRepository();
    });

    test('list returns initial fleet of 10 buses', () async {
      final vehicles = await repo.list();
      expect(vehicles.length, 10);
      expect(vehicles.any((v) => v.make == 'Ashok Leyland'), isTrue);
      expect(vehicles.any((v) => v.make == 'Tata Motors'), isTrue);
      expect(vehicles.any((v) => v.make == 'Volvo'), isTrue);
      expect(vehicles.any((v) => v.make == 'Eicher'), isTrue);
    });

    test('get vehicle by ID returns expected vehicle', () async {
      final vehicle = await repo.get('veh-001');
      expect(vehicle.registrationNo, 'TS 09 UB 4521');
      expect(vehicle.status, VehicleStatus.active);
    });

    test('create, update, and delete vehicle', () async {
      final newVehicle = Vehicle(
        id: 'veh-new',
        registrationNo: 'TS 09 ZZ 9999',
        make: 'Tata Motors',
        model: 'Starbus EV',
        year: 2024,
        chassisNo: 'CH-EV-1',
        engineNo: 'ENG-EV-1',
        seats: 35,
        fuelType: 'Electric',
        odometerKm: 5000,
        depot: 'Hyderabad Central',
        purchaseDate: DateTime.now(),
        status: VehicleStatus.active,
      );

      final created = await repo.create(newVehicle);
      expect(created.id, 'veh-new');

      final listAfterAdd = await repo.list();
      expect(listAfterAdd.length, 11);

      await repo.delete('veh-new');
      final listAfterDel = await repo.list();
      expect(listAfterDel.length, 10);
    });

    test('failing path throws SimulationException on fail-id', () async {
      expect(
        () => repo.get('fail-id'),
        throwsA(isA<SimulationException>()),
      );
    });
  });

  group('MockServiceRepository Tests', () {
    late MockServiceRepository repo;

    setUp(() {
      repo = MockServiceRepository();
    });

    test('listAll returns historical services and can filter by vehicle',
        () async {
      final allServices = await repo.listAll();
      expect(allServices.length, greaterThanOrEqualTo(40));

      final veh1Services = await repo.listAll(vehicleId: 'veh-001');
      expect(veh1Services, isNotEmpty);
      expect(veh1Services.every((s) => s.vehicleId == 'veh-001'), isTrue);
    });

    test('upcomingTasks returns due tasks and setTaskDone works', () async {
      final tasks = await repo.upcomingTasks();
      expect(tasks, isNotEmpty);

      final firstTaskId = tasks.first.id;
      await repo.setTaskDone(firstTaskId, true);

      final tasksAfter = await repo.upcomingTasks();
      expect(tasksAfter.any((t) => t.id == firstTaskId), isFalse);
    });

    test('failing path throws SimulationException on fail-id', () async {
      expect(
        () => repo.get('fail-id'),
        throwsA(isA<SimulationException>()),
      );
    });
  });

  group('MockBillRepository & MockOcrService Tests', () {
    test('bill repository operations and failing path', () async {
      final repo = MockBillRepository();
      final bills = await repo.listAll();
      expect(bills, isNotEmpty);

      expect(
        () => repo.get('fail-id'),
        throwsA(isA<SimulationException>()),
      );
    });

    test('ocr service scan and failure path', () async {
      final ocr = MockOcrService();
      final result = await ocr.scanBill('assets/mock/bill_sample.jpg');
      expect(result.vendor, isNotNull);
      expect(result.confidence, greaterThan(0.9));

      expect(
        () => ocr.scanBill('fail_path.jpg'),
        throwsA(isA<SimulationException>()),
      );
    });
  });

  group('MockUserRepository & MockSettingsRepository Tests', () {
    test('user repository listing, invitation, and failing path', () async {
      final userRepo = MockUserRepository();
      final users = await userRepo.list();
      expect(users.length, 5);

      final invited = await userRepo.invite(
        name: 'New Staff',
        email: 'staff.new@fleetpulse.com',
        password: 'FleetPulseTest!2026',
        role: UserRole.staff,
        phone: '+91 99887 76655',
      );
      expect(invited.status, UserStatus.active);

      expect(
        () => userRepo.get('fail-id'),
        throwsA(isA<SimulationException>()),
      );
    });

    test('settings repository saves and retrieves preferences', () async {
      final settingsRepo = MockSettingsRepository();
      final initial = await settingsRepo.getUserSettings();
      expect(initial.themeMode, 'system');

      await settingsRepo.saveUserSettings(
        initial.copyWith(themeMode: 'dark', language: 'te'),
      );

      final updated = await settingsRepo.getUserSettings();
      expect(updated.themeMode, 'dark');
      expect(updated.language, 'te');
    });
  });
}
