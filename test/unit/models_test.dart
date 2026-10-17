import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/features/auth/domain/app_user.dart';
import 'package:bus_app/features/vehicles/domain/vehicle.dart';
import 'package:bus_app/features/vehicles/domain/vehicle_document.dart';
import 'package:bus_app/features/vehicles/domain/vehicle_status.dart';
import 'package:bus_app/features/services/domain/service_record.dart';
import 'package:bus_app/features/services/domain/maintenance_task.dart';
import 'package:bus_app/features/bills/domain/bill.dart';
import 'package:bus_app/features/settings/domain/user_settings.dart';
import 'package:bus_app/features/settings/domain/company_settings.dart';

void main() {
  group('AppUser Model Tests', () {
    test('AppUser serialization, deserialization, and copyWith', () {
      const user = AppUser(
        id: 'usr-1',
        name: 'Karthik',
        email: 'karthik@fleetpulse.com',
        phone: '+91 98490 12345',
        role: UserRole.admin,
        status: UserStatus.active,
      );

      expect(user.isAdmin, isTrue);
      expect(user.isStaff, isFalse);

      final json = user.toJson();
      final fromJson = AppUser.fromJson(json);

      expect(fromJson, equals(user));

      final updated = user.copyWith(name: 'Karthik T');
      expect(updated.name, 'Karthik T');
      expect(updated.id, 'usr-1');
    });
  });

  group('Vehicle & VehicleDocument Model Tests', () {
    test('vehicle statuses accept database snake_case values', () {
      expect(VehicleStatus.fromStorage('active'), VehicleStatus.active);
      expect(VehicleStatus.fromStorage('overdue'), VehicleStatus.overdue);
      expect(
          VehicleStatus.fromStorage('in_workshop'), VehicleStatus.inWorkshop);
      expect(VehicleStatus.fromStorage('due_soon'), VehicleStatus.dueSoon);
      expect(VehicleStatus.fromStorage('dueSoon'), VehicleStatus.dueSoon);
      expect(VehicleStatus.fromStorage('unexpected'), VehicleStatus.active);
    });

    test('vehicle statuses serialize to database snake_case values', () {
      expect(VehicleStatus.active.dbValue, 'active');
      expect(VehicleStatus.dueSoon.dbValue, 'due_soon');
      expect(VehicleStatus.overdue.dbValue, 'overdue');
      expect(VehicleStatus.inWorkshop.dbValue, 'in_workshop');
    });

    test('Vehicle serialization and copyWith', () {
      final now = DateTime.now();
      final doc = VehicleDocument(
        id: 'doc-1',
        type: DocumentType.insurance,
        number: 'INS-101',
        expiryDate: now.add(const Duration(days: 30)),
      );

      final vehicle = Vehicle(
        id: 'veh-1',
        registrationNo: 'TS 09 UB 4521',
        make: 'Ashok Leyland',
        model: 'Viking 222',
        year: 2021,
        chassisNo: 'CHASSIS-1',
        engineNo: 'ENG-1',
        seats: 44,
        fuelType: 'Diesel',
        odometerKm: 140000,
        depot: 'Hyderabad Central',
        purchaseDate: now.subtract(const Duration(days: 500)),
        status: VehicleStatus.active,
        documents: [doc],
      );

      expect(vehicle.displayName, 'Ashok Leyland Viking 222 (TS 09 UB 4521)');
      expect(doc.isExpired, isFalse);

      final json = vehicle.toJson();
      final fromJson = Vehicle.fromJson(json);

      expect(fromJson.id, vehicle.id);
      expect(fromJson.registrationNo, vehicle.registrationNo);
      expect(fromJson.documents.length, 1);
      expect(fromJson.documents.first.number, 'INS-101');

      final updated = vehicle.copyWith(odometerKm: 145000);
      expect(updated.odometerKm, 145000);
      expect(updated.status, VehicleStatus.active);
    });
  });

  group('ServiceRecord & MaintenanceTask Model Tests', () {
    test('ServiceRecord and MaintenanceTask serialization', () {
      final now = DateTime.now();
      const part = ServicePart(
        id: 'prt-1',
        name: 'Oil Filter',
        quantity: 1,
        costPerUnit: 1200,
        totalCost: 1200,
      );

      final record = ServiceRecord(
        id: 'srv-1',
        vehicleId: 'veh-1',
        type: ServiceType.oilChange,
        date: now,
        odometerKm: 140000,
        workshop: 'Balaji Works',
        mechanic: 'Ramesh',
        notes: 'Oil changed',
        parts: [part],
        labourCost: 2000,
        tax: 500,
        total: 3700,
      );

      final json = record.toJson();
      final fromJson = ServiceRecord.fromJson(json);

      expect(fromJson.id, record.id);
      expect(fromJson.parts.length, 1);
      expect(fromJson.parts.first.name, 'Oil Filter');
      expect(fromJson.total, 3700);

      final task = MaintenanceTask(
        id: 'tsk-1',
        vehicleId: 'veh-1',
        title: 'PUC Renewal',
        dueDate: now.subtract(const Duration(days: 2)),
      );

      expect(task.isOverdue, isTrue);

      final taskJson = task.toJson();
      final taskFromJson = MaintenanceTask.fromJson(taskJson);
      expect(taskFromJson.id, task.id);
      expect(taskFromJson.isOverdue, isTrue);
    });
  });

  group('Bill Model Tests', () {
    test('Bill and BillItem serialization', () {
      final now = DateTime.now();
      const item = BillItem(
          name: 'Engine Oil', quantity: 1, unitCost: 6500, total: 6500);

      final bill = Bill(
        id: 'bill-1',
        vehicleId: 'veh-1',
        serviceId: 'srv-1',
        vendor: 'Sri Balaji Works',
        billNo: 'INV-100',
        billDate: now,
        items: [item],
        tax: 1170,
        total: 7670,
      );

      final json = bill.toJson();
      final fromJson = Bill.fromJson(json);

      expect(fromJson.billNo, 'INV-100');
      expect(fromJson.total, 7670);
      expect(fromJson.items.length, 1);
    });
  });

  group('Settings Model Tests', () {
    test('UserSettings and CompanySettings serialization', () {
      const userSettings = UserSettings(
        themeMode: 'dark',
        notificationsEnabled: true,
        serviceReminderLeadDays: 10,
      );

      final json = userSettings.toJson();
      final fromJson = UserSettings.fromJson(json);

      expect(fromJson.themeMode, 'dark');
      expect(fromJson.serviceReminderLeadDays, 10);

      const compSettings = CompanySettings(
        name: 'FleetPulse Express',
        depots: ['Depot A', 'Depot B'],
      );

      final compJson = compSettings.toJson();
      final compFromJson = CompanySettings.fromJson(compJson);

      expect(compFromJson.name, 'FleetPulse Express');
      expect(compFromJson.depots.length, 2);
    });
  });
}
