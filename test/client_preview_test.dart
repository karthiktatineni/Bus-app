import 'dart:async';

import 'package:bus_app/core/theme/app_theme.dart';
import 'package:bus_app/features/auth/providers.dart';
import 'package:bus_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:bus_app/features/services/presentation/service_history_screen.dart';
import 'package:bus_app/features/services/presentation/service_detail_screen.dart';
import 'package:bus_app/features/services/presentation/add_service_screen.dart';
import 'package:bus_app/features/services/providers.dart';
import 'package:bus_app/features/vehicles/presentation/vehicles_list_screen.dart';
import 'package:bus_app/features/vehicles/presentation/add_edit_vehicle_screen.dart';
import 'package:bus_app/features/vehicles/presentation/vehicle_detail_screen.dart';
import 'package:bus_app/features/vehicles/providers.dart';
import 'package:bus_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client preview interactions', () {
    testWidgets('dashboard and fleet lists fit a narrow phone viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _screenWith(
          user: _adminUser,
          vehicleRepository: _FakeVehicleRepository(_vehicles),
          serviceRepository: _FakeServiceRepository(records: _serviceRecords),
          child: const DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final vehicleListError = tester.takeException();
      expect(vehicleListError, isNull, reason: vehicleListError?.toString());

      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          vehicleRepository: _FakeVehicleRepository(_vehicles),
          child: const VehiclesListScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _screenWith(
          user: _adminUser,
          child: const AddEditVehicleScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -560));
      await tester.pumpAndSettle();
      expect(find.text('Add bus photos'), findsOneWidget);
      expect(find.text('Scan / add document'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          serviceRepository: _FakeServiceRepository(records: _serviceRecords),
          child: const ServiceDetailScreen(serviceId: 'srv-oil'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add service photo'), findsOneWidget);
      expect(find.byTooltip('Edit service record'), findsNothing);
      expect(find.byTooltip('Delete service record'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          serviceRepository: _FakeServiceRepository(records: _serviceRecords),
          child: const ServiceHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('to-do checklist completion can be undone', (tester) async {
      await tester.pumpWidget(
        _appWith(
          user: _adminUser,
          serviceRepository: _FakeServiceRepository(
            tasks: [
              MaintenanceTask(
                id: 'task-brake-lines',
                vehicleId: 'veh-active',
                title: 'Inspect brake lines',
                dueDate: DateTime.now().add(const Duration(days: 2)),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inspect brake lines'), findsWidgets);

      final taskCheckbox = find.byType(Checkbox).first;
      await tester.drag(find.byType(ListView).first, const Offset(0, -420));
      await tester.pumpAndSettle();
      await tester.ensureVisible(taskCheckbox);
      await tester.tap(taskCheckbox);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
          _hasTaskDecoration('Inspect brake lines', TextDecoration.lineThrough),
          isTrue);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(
          _hasTaskDecoration('Inspect brake lines', TextDecoration.lineThrough),
          isFalse);
    });

    testWidgets('to-do shows vehicle due-soon and overdue status without tasks',
        (tester) async {
      await tester.pumpWidget(_screenWith(
        user: _adminUser,
        vehicleRepository: _FakeVehicleRepository(_vehicles),
        serviceRepository: _FakeServiceRepository(),
        child: const DashboardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Service overdue'), findsOneWidget);
      expect(find.textContaining('Service due soon'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vehicle service history exposes add-service action',
        (tester) async {
      await tester.pumpWidget(_screenWith(
        user: _adminUser,
        vehicleRepository: _FakeVehicleRepository(_vehicles),
        serviceRepository: _FakeServiceRepository(),
        child: const VehicleDetailScreen(vehicleId: 'veh-active'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service history'));
      await tester.pumpAndSettle();
      expect(find.text('Add service record'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('service entry form fits a narrow phone viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_screenWith(
        user: _staffUser,
        vehicleRepository: _FakeVehicleRepository(_vehicles),
        serviceRepository: _FakeServiceRepository(),
        child: const AddServiceScreen(preselectedVehicleId: 'veh-active'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Service Record'), findsOneWidget);
      expect(find.text('Bill OCR Scanner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('role-aware drawer shows admin-only actions only for admins',
        (tester) async {
      await tester.pumpWidget(_appWith(user: _adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Add vehicle'), findsOneWidget);

      await tester.drag(find.byType(ListView).last, const Offset(0, -260));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(_appWith(user: _staffUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsNothing);
      expect(find.text('Add vehicle'), findsNothing);
    });

    testWidgets('vehicle search and multi-word status filter narrow the list',
        (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          vehicleRepository: _FakeVehicleRepository(_vehicles),
          child: VehiclesListScreen(key: UniqueKey()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KA-01-AA-0001'), findsOneWidget);
      expect(find.text('KA-02-BB-0002'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'volvo');
      await tester.pumpAndSettle();

      expect(find.text('KA-01-AA-0001'), findsOneWidget);
      expect(find.text('KA-02-BB-0002'), findsNothing);

      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          vehicleRepository: _FakeVehicleRepository(_vehicles),
          child: const VehiclesListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Due soon (1)'));
      await tester.pumpAndSettle();

      expect(find.text('KA-03-CC-0003'), findsOneWidget);
      expect(find.text('KA-01-AA-0001'), findsNothing);
    });

    testWidgets('vehicle list reflects streamed database updates',
        (tester) async {
      final updates = StreamController<List<Vehicle>>();
      final repository = _FakeVehicleRepository(_vehicles, updates: updates);
      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          vehicleRepository: repository,
          child: const VehiclesListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KA-04-DD-0004'), findsNothing);
      updates.add([
        ..._vehicles,
        _vehicles.first.copyWith(
          id: 'veh-live-update',
          registrationNo: 'KA-04-DD-0004',
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('KA-04-DD-0004'), findsOneWidget);
      await updates.close();
    });

    testWidgets('service record search and category filter narrow the list',
        (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          serviceRepository: _FakeServiceRepository(records: _serviceRecords),
          child: ServiceHistoryScreen(key: UniqueKey()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'meera');
      await tester.pumpAndSettle();

      expect(find.text('Oil & Filter Change'), findsOneWidget);
      expect(find.text('Brake Overhaul'), findsNothing);

      await tester.pumpWidget(
        _screenWith(
          user: _staffUser,
          serviceRepository: _FakeServiceRepository(records: _serviceRecords),
          child: const ServiceHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Brake'));
      await tester.pumpAndSettle();

      expect(find.text('Brake Overhaul'), findsOneWidget);
      expect(find.text('Oil & Filter Change'), findsNothing);
    });
  });
}

Widget _appWith({
  required AppUser user,
  VehicleRepository? vehicleRepository,
  ServiceRepository? serviceRepository,
}) {
  return ProviderScope(
    key: ValueKey('app-${user.id}'),
    overrides: _overrides(
      user: user,
      vehicleRepository: vehicleRepository,
      serviceRepository: serviceRepository,
    ),
    child: const FleetPulseApp(),
  );
}

Widget _screenWith({
  required AppUser user,
  VehicleRepository? vehicleRepository,
  ServiceRepository? serviceRepository,
  required Widget child,
}) {
  return ProviderScope(
    key: ValueKey('screen-${user.id}'),
    overrides: _overrides(
      user: user,
      vehicleRepository: vehicleRepository,
      serviceRepository: serviceRepository,
    ),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

List<Override> _overrides({
  required AppUser user,
  VehicleRepository? vehicleRepository,
  ServiceRepository? serviceRepository,
}) {
  return [
    authControllerProvider
        .overrideWith((ref) => _SeededAuthController(ref, user)),
    vehicleRepositoryProvider.overrideWithValue(
        vehicleRepository ?? _FakeVehicleRepository(_vehicles)),
    serviceRepositoryProvider
        .overrideWithValue(serviceRepository ?? _FakeServiceRepository()),
  ];
}

bool _hasTaskDecoration(String text, TextDecoration decoration) {
  return find
      .byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == text &&
            widget.style?.decoration?.contains(decoration) == true,
      )
      .evaluate()
      .isNotEmpty;
}

class _SeededAuthController extends AuthController {
  _SeededAuthController(super.ref, AppUser user) {
    state = AuthState(user: user);
  }
}

class _FakeVehicleRepository implements VehicleRepository {
  _FakeVehicleRepository(this._vehicles, {this.updates});

  final List<Vehicle> _vehicles;
  final StreamController<List<Vehicle>>? updates;

  @override
  Future<List<Vehicle>> list() async => List.unmodifiable(_vehicles);

  @override
  Stream<List<Vehicle>> watch() =>
      updates?.stream ?? Stream.value(List.unmodifiable(_vehicles));

  @override
  Future<Vehicle> get(String id) async =>
      _vehicles.firstWhere((vehicle) => vehicle.id == id);

  @override
  Future<Vehicle> create(Vehicle v) async => v;

  @override
  Future<Vehicle> update(Vehicle v) async => v;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deletePhoto(String vehicleId, String photoUrl) async {}

  @override
  Future<void> addPhoto(String vehicleId, String filePath) async {}
}

class _FakeServiceRepository implements ServiceRepository {
  _FakeServiceRepository({
    List<ServiceRecord>? records,
    List<MaintenanceTask>? tasks,
  })  : _records = records ?? const [],
        _tasks = tasks ?? const [];

  final List<ServiceRecord> _records;
  final List<MaintenanceTask> _tasks;

  @override
  Future<List<ServiceRecord>> listAll({String? vehicleId}) async {
    if (vehicleId == null) return List.unmodifiable(_records);
    return _records.where((record) => record.vehicleId == vehicleId).toList();
  }

  @override
  Future<ServiceRecord> get(String id) async =>
      _records.firstWhere((record) => record.id == id);

  @override
  Future<ServiceRecord> create(ServiceRecord r) async => r;

  @override
  Future<ServiceRecord> update(ServiceRecord r) async => r;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deletePhoto(String serviceId, String photoId) async {}

  @override
  Future<void> addPhoto(
      String serviceId, String filePath, PhotoType type) async {}

  @override
  Future<List<MaintenanceTask>> upcomingTasks({int withinDays = 14}) async =>
      List.unmodifiable(_tasks);

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    _tasks.add(task);
    return task;
  }

  @override
  Future<MaintenanceTask?> taskForService(String serviceRecordId) async {
    for (final task in _tasks) {
      if (task.serviceRecordId == serviceRecordId) return task;
    }
    return null;
  }

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async => task;

  @override
  Future<void> setTaskDone(String taskId, bool done) async {}

  @override
  Future<List<ServiceSchedule>> listSchedules({String? vehicleId}) async =>
      const [];

  @override
  Future<ServiceSchedule> createSchedule(ServiceSchedule s) async => s;

  @override
  Future<ServiceSchedule> updateSchedule(ServiceSchedule s) async => s;
}

const _adminUser = AppUser(
  id: 'user-admin',
  name: 'Karthik Tatineni',
  email: 'karthik@fleetpulse.com',
  phone: '9999999999',
  role: UserRole.admin,
  status: UserStatus.active,
);

const _staffUser = AppUser(
  id: 'user-staff',
  name: 'Staff Operator',
  email: 'staff@fleetpulse.com',
  phone: '8888888888',
  role: UserRole.staff,
  status: UserStatus.active,
);

final _vehicles = [
  Vehicle(
    id: 'veh-active',
    registrationNo: 'KA-01-AA-0001',
    make: 'Volvo',
    model: '9400',
    year: 2021,
    chassisNo: 'CHAS-ACTIVE',
    engineNo: 'ENG-ACTIVE',
    seats: 45,
    fuelType: 'Diesel',
    odometerKm: 120000,
    depot: 'Bengaluru Central',
    purchaseDate: DateTime(2021),
    status: VehicleStatus.active,
  ),
  Vehicle(
    id: 'veh-overdue',
    registrationNo: 'KA-02-BB-0002',
    make: 'Tata',
    model: 'Starbus',
    year: 2020,
    chassisNo: 'CHAS-OVERDUE',
    engineNo: 'ENG-OVERDUE',
    seats: 40,
    fuelType: 'Diesel',
    odometerKm: 190000,
    depot: 'Mysuru',
    purchaseDate: DateTime(2020),
    status: VehicleStatus.overdue,
  ),
  Vehicle(
    id: 'veh-due-soon',
    registrationNo: 'KA-03-CC-0003',
    make: 'Ashok Leyland',
    model: 'Viking',
    year: 2022,
    chassisNo: 'CHAS-DUE',
    engineNo: 'ENG-DUE',
    seats: 42,
    fuelType: 'Diesel',
    odometerKm: 90000,
    depot: 'Hubballi',
    purchaseDate: DateTime(2022),
    status: VehicleStatus.dueSoon,
  ),
];

final _serviceRecords = [
  ServiceRecord(
    id: 'srv-oil',
    vehicleId: 'veh-active',
    type: ServiceType.oilChange,
    date: DateTime(2026, 9, 1),
    odometerKm: 120000,
    workshop: 'Central Depot Workshop',
    mechanic: 'Meera',
    notes: 'Oil and filter replacement.',
    labourCost: 1200,
    tax: 216,
    total: 5416,
  ),
  ServiceRecord(
    id: 'srv-brake',
    vehicleId: 'veh-overdue',
    type: ServiceType.brakeService,
    date: DateTime(2026, 9, 7),
    odometerKm: 190000,
    workshop: 'North Bay Workshop',
    mechanic: 'Ravi',
    notes: 'Brake overhaul.',
    labourCost: 2400,
    tax: 432,
    total: 12832,
  ),
];
