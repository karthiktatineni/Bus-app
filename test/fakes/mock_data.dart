import 'package:bus_app/features/auth/domain/app_user.dart';
import 'package:bus_app/features/vehicles/domain/vehicle.dart';
import 'package:bus_app/features/vehicles/domain/vehicle_document.dart';
import 'package:bus_app/features/vehicles/domain/vehicle_status.dart';
import 'package:bus_app/features/services/domain/service_record.dart';
import 'package:bus_app/features/services/domain/maintenance_task.dart';
import 'package:bus_app/features/services/domain/service_schedule.dart';
import 'package:bus_app/features/bills/domain/bill.dart';
import 'package:bus_app/features/settings/domain/user_settings.dart';
import 'package:bus_app/features/settings/domain/company_settings.dart';

class MockData {
  static final DateTime now = DateTime.now();

  // ---------------------------------------------------------
  // 5 USERS (2 Admin, 3 Staff)
  // ---------------------------------------------------------
  static List<AppUser> generateUsers() {
    return [
      const AppUser(
        id: 'usr-001',
        name: 'Karthik Tatineni',
        email: 'karthik@fleetpulse.com',
        phone: '+91 98490 12345',
        role: UserRole.admin,
        status: UserStatus.active,
        avatarUrl: 'assets/mock/avatar_karthik.jpg',
      ),
      const AppUser(
        id: 'usr-002',
        name: 'Rajesh Varma',
        email: 'rajesh@fleetpulse.com',
        phone: '+91 98765 43210',
        role: UserRole.admin,
        status: UserStatus.active,
      ),
      const AppUser(
        id: 'usr-003',
        name: 'Staff Operator',
        email: 'staff@fleetpulse.com',
        phone: '+91 91234 56789',
        role: UserRole.staff,
        status: UserStatus.active,
      ),
      const AppUser(
        id: 'usr-004',
        name: 'Vijay Reddy',
        email: 'vijay@fleetpulse.com',
        phone: '+91 90001 22334',
        role: UserRole.staff,
        status: UserStatus.active,
      ),
      const AppUser(
        id: 'usr-005',
        name: 'Anita Sharma',
        email: 'anita@fleetpulse.com',
        phone: '+91 94400 88990',
        role: UserRole.staff,
        status: UserStatus.invited,
      ),
    ];
  }

  // ---------------------------------------------------------
  // 10 BUSES (Ashok Leyland, Tata, Eicher, Volvo)
  // 6 Active, 2 Due Soon, 1 Overdue, 1 In Workshop
  // ---------------------------------------------------------
  static List<Vehicle> generateVehicles() {
    return [
      // 1. Active - Ashok Leyland Viking
      Vehicle(
        id: 'veh-001',
        registrationNo: 'TS 09 UB 4521',
        make: 'Ashok Leyland',
        model: 'Viking 222',
        year: 2021,
        chassisNo: 'MB1A2B3C4D5E6F701',
        engineNo: 'ALH6E123456',
        seats: 44,
        fuelType: 'Diesel',
        odometerKm: 142500,
        depot: 'Hyderabad Central',
        purchaseDate: now.subtract(const Duration(days: 365 * 3)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_1.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-001-1',
            type: DocumentType.insurance,
            number: 'ICICI-LOMB-882103',
            expiryDate: now.add(const Duration(days: 120)),
          ),
          VehicleDocument(
            id: 'doc-001-2',
            type: DocumentType.fitness,
            number: 'TS09-FC-99214',
            expiryDate: now.add(const Duration(days: 90)),
          ),
          VehicleDocument(
            id: 'doc-001-3',
            type: DocumentType.puc,
            number: 'PUC-TS09-2026-01',
            expiryDate: now.add(const Duration(days: 45)),
          ),
        ],
      ),

      // 2. Due Soon - Tata Starbus
      Vehicle(
        id: 'veh-002',
        registrationNo: 'TS 07 UA 1122',
        make: 'Tata Motors',
        model: 'Starbus Ultra',
        year: 2022,
        chassisNo: 'MAT612345H123402',
        engineNo: 'TT33D654321',
        seats: 36,
        fuelType: 'Diesel',
        odometerKm: 98400,
        depot: 'Secunderabad Depot',
        purchaseDate: now.subtract(const Duration(days: 365 * 2)),
        status: VehicleStatus.dueSoon,
        photos: const ['assets/mock/bus_sample_2.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-002-1',
            type: DocumentType.insurance,
            number: 'BAJAJ-ALL-119283',
            expiryDate: now.add(const Duration(days: 18)),
          ),
          VehicleDocument(
            id: 'doc-002-2',
            type: DocumentType.fitness,
            number: 'TS07-FC-44012',
            expiryDate: now.add(const Duration(days: 8)),
          ),
        ],
      ),

      // 3. Overdue - Eicher Skyline Pro
      Vehicle(
        id: 'veh-003',
        registrationNo: 'AP 28 Z 8844',
        make: 'Eicher',
        model: 'Skyline Pro 3009',
        year: 2019,
        chassisNo: 'MC2E45678J987603',
        engineNo: 'E483T112233',
        seats: 32,
        fuelType: 'Diesel',
        odometerKm: 285600,
        depot: 'Warangal Depot',
        purchaseDate: now.subtract(const Duration(days: 365 * 5)),
        status: VehicleStatus.overdue,
        photos: const ['assets/mock/bus_sample_1.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-003-1',
            type: DocumentType.puc,
            number: 'PUC-AP28-2025-99',
            expiryDate: now.subtract(const Duration(days: 4)),
          ),
          VehicleDocument(
            id: 'doc-003-2',
            type: DocumentType.fitness,
            number: 'AP28-FC-12883',
            expiryDate: now.subtract(const Duration(days: 12)),
          ),
        ],
      ),

      // 4. In Workshop - Volvo 9600 Multi-Axle
      Vehicle(
        id: 'veh-004',
        registrationNo: 'TS 08 U 9900',
        make: 'Volvo',
        model: '9600 Sleeper B11R',
        year: 2023,
        chassisNo: 'YV2R45678B119604',
        engineNo: 'D11K430HP04',
        seats: 40,
        fuelType: 'Diesel',
        odometerKm: 82000,
        depot: 'Hyderabad Central',
        purchaseDate: now.subtract(const Duration(days: 365)),
        status: VehicleStatus.inWorkshop,
        photos: const ['assets/mock/bus_sample_2.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-004-1',
            type: DocumentType.insurance,
            number: 'HDFC-ERGO-778811',
            expiryDate: now.add(const Duration(days: 210)),
          ),
        ],
      ),

      // 5. Active - Ashok Leyland Falcon
      Vehicle(
        id: 'veh-005',
        registrationNo: 'TS 09 UA 3341',
        make: 'Ashok Leyland',
        model: 'Falcon 1618',
        year: 2020,
        chassisNo: 'MB1B3C4D5E6F705',
        engineNo: 'ALH6F987654',
        seats: 50,
        fuelType: 'Diesel',
        odometerKm: 210400,
        depot: 'Secunderabad Depot',
        purchaseDate: now.subtract(const Duration(days: 365 * 4)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_1.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-005-1',
            type: DocumentType.permit,
            number: 'PERM-TS-INTER-449',
            expiryDate: now.add(const Duration(days: 180)),
          ),
        ],
      ),

      // 6. Due Soon - Tata LP 410
      Vehicle(
        id: 'veh-006',
        registrationNo: 'AP 16 X 7721',
        make: 'Tata Motors',
        model: 'LP 410 City Express',
        year: 2018,
        chassisNo: 'MAT612345H123406',
        engineNo: 'TT497SPTC06',
        seats: 30,
        fuelType: 'Diesel',
        odometerKm: 345000,
        depot: 'Warangal Depot',
        purchaseDate: now.subtract(const Duration(days: 365 * 6)),
        status: VehicleStatus.dueSoon,
        photos: const ['assets/mock/bus_sample_2.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-006-1',
            type: DocumentType.insurance,
            number: 'NEW-INDIA-664402',
            expiryDate: now.add(const Duration(days: 6)),
          ),
        ],
      ),

      // 7. Active - BharatBenz 1624
      Vehicle(
        id: 'veh-007',
        registrationNo: 'TS 10 UB 5566',
        make: 'BharatBenz',
        model: '1624 Intercity',
        year: 2022,
        chassisNo: 'ME4B1624CDE55607',
        engineNo: 'OM926LA07',
        seats: 46,
        fuelType: 'Diesel',
        odometerKm: 115200,
        depot: 'Hyderabad Central',
        purchaseDate: now.subtract(const Duration(days: 365 * 2)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_1.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-007-1',
            type: DocumentType.fitness,
            number: 'TS10-FC-88712',
            expiryDate: now.add(const Duration(days: 140)),
          ),
        ],
      ),

      // 8. Active - Eicher 20.15
      Vehicle(
        id: 'veh-008',
        registrationNo: 'TS 09 UC 6611',
        make: 'Eicher',
        model: 'Starline 20.15 R',
        year: 2017,
        chassisNo: 'MC2E2015H987608',
        engineNo: 'E494T089911',
        seats: 52,
        fuelType: 'Diesel',
        odometerKm: 420000,
        depot: 'Secunderabad Depot',
        purchaseDate: now.subtract(const Duration(days: 365 * 7)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_2.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-008-1',
            type: DocumentType.permit,
            number: 'PERM-TS-INTER-882',
            expiryDate: now.add(const Duration(days: 95)),
          ),
        ],
      ),

      // 9. Active - Tata LPO 1618
      Vehicle(
        id: 'veh-009',
        registrationNo: 'AP 29 V 1234',
        make: 'Tata Motors',
        model: 'LPO 1618 BS6',
        year: 2024,
        chassisNo: 'MAT61618BS612309',
        engineNo: 'CUMMINS56D09',
        seats: 48,
        fuelType: 'Diesel',
        odometerKm: 46500,
        depot: 'Hyderabad Central',
        purchaseDate: now.subtract(const Duration(days: 180)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_1.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-009-1',
            type: DocumentType.insurance,
            number: 'ROYAL-SUND-449102',
            expiryDate: now.add(const Duration(days: 300)),
          ),
        ],
      ),

      // 10. Active - Ashok Leyland Oyster
      Vehicle(
        id: 'veh-010',
        registrationNo: 'TS 07 UB 9012',
        make: 'Ashok Leyland',
        model: 'Oyster Wide',
        year: 2023,
        chassisNo: 'MB1OYSTER202310',
        engineNo: 'H4E101122',
        seats: 41,
        fuelType: 'Diesel',
        odometerKm: 78900,
        depot: 'Warangal Depot',
        purchaseDate: now.subtract(const Duration(days: 365)),
        status: VehicleStatus.active,
        photos: const ['assets/mock/bus_sample_2.jpg'],
        documents: [
          VehicleDocument(
            id: 'doc-010-1',
            type: DocumentType.fitness,
            number: 'TS07-FC-77123',
            expiryDate: now.add(const Duration(days: 160)),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------
  // HISTORICAL SERVICES (3 to 8 services per bus, costs ₹2,500 to ₹1,80,000)
  // ---------------------------------------------------------
  static List<ServiceRecord> generateServiceRecords() {
    final List<ServiceRecord> records = [];

    // Realistic common part sets
    final partsOilChange = [
      const ServicePart(
        id: 'prt-101',
        name: 'Castrol VECTON 15W-40 Engine Oil (20L)',
        quantity: 1,
        costPerUnit: 6800.0,
        totalCost: 6800.0,
        partNumber: 'CAS-VEC-1540',
      ),
      const ServicePart(
        id: 'prt-102',
        name: 'Fleetguard Oil Filter Cartridge',
        quantity: 1,
        costPerUnit: 1250.0,
        totalCost: 1250.0,
        partNumber: 'FLG-LF16015',
      ),
      const ServicePart(
        id: 'prt-103',
        name: 'Diesel Fuel Filter Primary & Secondary',
        quantity: 2,
        costPerUnit: 850.0,
        totalCost: 1700.0,
        partNumber: 'BOSCH-FF-441',
      ),
    ];

    final partsBrakeOverhaul = [
      const ServicePart(
        id: 'prt-201',
        name: 'Brake Lining Set (Front & Rear)',
        quantity: 4,
        costPerUnit: 3400.0,
        totalCost: 13600.0,
        partNumber: 'TVS-BRK-881',
      ),
      const ServicePart(
        id: 'prt-202',
        name: 'Brake Drum Resurfacing & Hardware',
        quantity: 2,
        costPerUnit: 1800.0,
        totalCost: 3600.0,
      ),
      const ServicePart(
        id: 'prt-203',
        name: 'WABCO Slack Adjuster Assembly',
        quantity: 2,
        costPerUnit: 2200.0,
        totalCost: 4400.0,
        partNumber: 'WABCO-SA-12',
      ),
    ];

    final partsClutchTransmission = [
      const ServicePart(
        id: 'prt-301',
        name: 'Valeo 380mm Clutch Plate Assembly',
        quantity: 1,
        costPerUnit: 24500.0,
        totalCost: 24500.0,
        partNumber: 'VAL-CP-380',
      ),
      const ServicePart(
        id: 'prt-302',
        name: 'Clutch Pressure Plate & Release Bearing',
        quantity: 1,
        costPerUnit: 16800.0,
        totalCost: 16800.0,
        partNumber: 'VAL-CPP-380',
      ),
      const ServicePart(
        id: 'prt-303',
        name: 'Gearbox Oil 80W-90 (15L)',
        quantity: 1,
        costPerUnit: 5200.0,
        totalCost: 5200.0,
      ),
    ];

    final partsTyres = [
      const ServicePart(
        id: 'prt-401',
        name: 'Apollo EnduMile 295/80 R22.5 Radial Tyre',
        quantity: 2,
        costPerUnit: 26500.0,
        totalCost: 53000.0,
        partNumber: 'APL-RAD-295',
      ),
      const ServicePart(
        id: 'prt-402',
        name: 'Wheel Balancing and Alignment Weights',
        quantity: 1,
        costPerUnit: 1500.0,
        totalCost: 1500.0,
      ),
    ];

    final partsMajorOverhaul = [
      const ServicePart(
        id: 'prt-501',
        name: 'Turbocharger Core Assembly',
        quantity: 1,
        costPerUnit: 48000.0,
        totalCost: 48000.0,
        partNumber: 'HOLSET-HX35W',
      ),
      const ServicePart(
        id: 'prt-502',
        name: 'Cylinder Head Gasket & Valve Seal Set',
        quantity: 1,
        costPerUnit: 14500.0,
        totalCost: 14500.0,
      ),
      const ServicePart(
        id: 'prt-503',
        name: 'Water Pump & Heavy Duty Radiator Core',
        quantity: 1,
        costPerUnit: 28000.0,
        totalCost: 28000.0,
      ),
    ];

    // Build 4 to 6 services for each of the 10 buses
    for (int i = 1; i <= 10; i++) {
      final vehId = 'veh-${i.toString().padLeft(3, '0')}';
      final baseOdo = 35000 + (i * 25000);

      // Service 1: Recent Oil & Filter change (15 to 45 days ago)
      records.add(
        ServiceRecord(
          id: 'srv-${i.toString().padLeft(2, '0')}1',
          vehicleId: vehId,
          type: ServiceType.oilChange,
          date: now.subtract(Duration(days: 15 + (i * 3))),
          odometerKm: baseOdo,
          workshop: 'Sri Balaji Heavy Workshop, Sanath Nagar',
          mechanic: 'Ramesh Chander',
          notes:
              'Regular engine oil and filter replacement. General inspection done.',
          parts: partsOilChange,
          labourCost: 2500.0,
          tax: 1800.0,
          total: 14050.0,
          photos: const [
            ServicePhoto(
                id: 'sph-1',
                url: 'assets/mock/bus_sample_1.jpg',
                type: PhotoType.after,
                caption: 'Oil drainage complete'),
          ],
          billId: 'bill-${i.toString().padLeft(2, '0')}1',
        ),
      );

      // Service 2: Brake service (60 to 110 days ago)
      records.add(
        ServiceRecord(
          id: 'srv-${i.toString().padLeft(2, '0')}2',
          vehicleId: vehId,
          type: ServiceType.brakeService,
          date: now.subtract(Duration(days: 60 + (i * 5))),
          odometerKm: baseOdo - 12000,
          workshop: 'Deccan Commercial Brake & Hub Services',
          mechanic: 'M. A. Khadeer',
          notes:
              'Replaced worn front and rear brake linings. Drum machined and slack adjuster tuned.',
          parts: partsBrakeOverhaul,
          labourCost: 4500.0,
          tax: 3200.0,
          total: 29300.0,
          photos: const [
            ServicePhoto(
                id: 'sph-2',
                url: 'assets/mock/bus_sample_2.jpg',
                type: PhotoType.part,
                caption: 'New brake shoe kit installed'),
          ],
          billId: 'bill-${i.toString().padLeft(2, '0')}2',
        ),
      );

      // Service 3: Routine Electrical / Battery check (140 to 190 days ago)
      records.add(
        ServiceRecord(
          id: 'srv-${i.toString().padLeft(2, '0')}3',
          vehicleId: vehId,
          type: ServiceType.electrical,
          date: now.subtract(Duration(days: 140 + (i * 4))),
          odometerKm: baseOdo - 25000,
          workshop: 'Amaron Power Zone Autoworks, Kukatpally',
          mechanic: 'Prakash Rao',
          notes:
              'Alternator belt tightened, terminal cleaning, headlamp relay replaced.',
          parts: const [
            ServicePart(
                id: 'prt-el-1',
                name: 'Lucas TVS Heavy Duty Alternator Belt',
                quantity: 1,
                costPerUnit: 1450.0,
                totalCost: 1450.0),
            ServicePart(
                id: 'prt-el-2',
                name: 'Bosch 24V 70A Headlamp Relay',
                quantity: 2,
                costPerUnit: 450.0,
                totalCost: 900.0),
          ],
          labourCost: 1200.0,
          tax: 450.0,
          total: 4000.0,
          photos: const [],
          billId: 'bill-${i.toString().padLeft(2, '0')}3',
        ),
      );

      // Service 4: Tyre rotation or replacement (220 to 280 days ago)
      records.add(
        ServiceRecord(
          id: 'srv-${i.toString().padLeft(2, '0')}4',
          vehicleId: vehId,
          type: ServiceType.tyreReplacement,
          date: now.subtract(Duration(days: 220 + (i * 6))),
          odometerKm: baseOdo - 38000,
          workshop: 'Apollo Tyres Commercial Hub, Medchal',
          mechanic: 'Sunil Goud',
          notes:
              'Fitted 2 new radial tyres on front steer axle. Rear tyres rotated and aligned.',
          parts: partsTyres,
          labourCost: 2000.0,
          tax: 9800.0,
          total: 66300.0,
          photos: const [],
          billId: 'bill-${i.toString().padLeft(2, '0')}4',
        ),
      );

      // Add a 5th major service for older/higher mileage buses (buses 1, 3, 4, 8)
      if (i == 1 || i == 3 || i == 4 || i == 8) {
        records.add(
          ServiceRecord(
            id: 'srv-${i.toString().padLeft(2, '0')}5',
            vehicleId: vehId,
            type: i == 4
                ? ServiceType.majorRepair
                : ServiceType.clutchReplacement,
            date: now.subtract(Duration(days: 310 + (i * 7))),
            odometerKm: baseOdo - 52000,
            workshop: i == 4
                ? 'Volvo Authorized Workshop, Shamshabad'
                : 'National Motors Commercial Centre',
            mechanic:
                i == 4 ? 'A. S. Murthy (Volvo Specialist)' : 'Mohd. Rafiq',
            notes: i == 4
                ? 'Complete turbocharger replacement, cylinder head gasket renewed, cooling flush.'
                : 'Clutch plate and pressure plate overhaul with new gearbox fluid.',
            parts: i == 4 ? partsMajorOverhaul : partsClutchTransmission,
            labourCost: i == 4 ? 22000.0 : 7500.0,
            tax: i == 4 ? 20500.0 : 8500.0,
            total: i == 4 ? 133000.0 : 62500.0,
            photos: const [
              ServicePhoto(
                  id: 'sph-3',
                  url: 'assets/mock/bus_sample_2.jpg',
                  type: PhotoType.before,
                  caption: 'Before disassembly'),
            ],
            billId: 'bill-${i.toString().padLeft(2, '0')}5',
          ),
        );
      }
    }

    return records;
  }

  // ---------------------------------------------------------
  // BILLS (Linked to Services)
  // ---------------------------------------------------------
  static List<Bill> generateBills(List<ServiceRecord> services) {
    return services.map((s) {
      return Bill(
        id: s.billId ?? 'bill-${s.id}',
        vehicleId: s.vehicleId,
        serviceId: s.id,
        vendor: s.workshop,
        billNo: 'INV-2026-${s.id.replaceAll('srv-', 'B')}',
        billDate: s.date,
        items: s.parts.map((p) {
          return BillItem(
            name: p.name,
            quantity: p.quantity,
            unitCost: p.costPerUnit,
            total: p.totalCost,
          );
        }).toList(),
        tax: s.tax,
        total: s.total,
        imageUrl: 'assets/mock/bill_sample.jpg',
        ocrConfidence: 0.96,
      );
    }).toList();
  }

  // ---------------------------------------------------------
  // SERVICE SCHEDULES (Intervals: km and months)
  // ---------------------------------------------------------
  static List<ServiceSchedule> generateSchedules() {
    final schedules = <ServiceSchedule>[];
    for (int i = 1; i <= 10; i++) {
      final vehId = 'veh-${i.toString().padLeft(3, '0')}';
      final baseOdo = 35000 + (i * 25000);

      schedules.addAll([
        ServiceSchedule(
          id: 'sch-oil-$i',
          vehicleId: vehId,
          taskName: 'Engine Oil & Filter Service',
          intervalKm: 10000,
          intervalMonths: 3,
          lastDoneDate: now.subtract(Duration(days: 15 + (i * 8))),
          lastDoneKm: baseOdo - 7500,
        ),
        ServiceSchedule(
          id: 'sch-brk-$i',
          vehicleId: vehId,
          taskName: 'Brake Overhaul & Lining Check',
          intervalKm: 20000,
          intervalMonths: 6,
          lastDoneDate: now.subtract(Duration(days: 60 + (i * 12))),
          lastDoneKm: baseOdo - 16000,
        ),
        ServiceSchedule(
          id: 'sch-clutch-$i',
          vehicleId: vehId,
          taskName: 'Clutch & Transmission Inspection',
          intervalKm: 40000,
          intervalMonths: 12,
          lastDoneDate: now.subtract(Duration(days: 180 + (i * 15))),
          lastDoneKm: baseOdo - 35000,
        ),
      ]);
    }
    return schedules;
  }

  // ---------------------------------------------------------
  // MAINTENANCE TASKS (Calculated from schedules + statutory deadlines)
  // ---------------------------------------------------------
  static List<MaintenanceTask> generateTasks(
      {List<Vehicle>? vehicles, List<ServiceSchedule>? schedules}) {
    final vehList = vehicles ?? generateVehicles();
    final schedList = schedules ?? generateSchedules();
    final tasks = <MaintenanceTask>[];

    int taskCounter = 1;

    // 1. Calculate tasks from schedules
    for (final schedule in schedList) {
      final vehicle = vehList.firstWhere(
        (v) => v.id == schedule.vehicleId,
        orElse: () => vehList.first,
      );

      final nextDueKm = schedule.nextDueKm;
      final nextDueDate = schedule.nextDueDate;
      final isDueByKm = vehicle.odometerKm >= nextDueKm;
      final daysDiff = nextDueDate.difference(now).inDays;

      // Include in task list if due soon (within 20 days) or due by km or overdue
      if (isDueByKm || daysDiff <= 20) {
        tasks.add(
          schedule.generateTask(
            taskId: 'tsk-${taskCounter.toString().padLeft(3, '0')}',
            currentOdometerKm: vehicle.odometerKm,
            currentDate: now,
          ),
        );
        taskCounter++;
      }
    }

    // 2. Add statutory document tasks (PUC, Fitness, Insurance)
    for (final vehicle in vehList) {
      for (final doc in vehicle.documents) {
        final daysDiff = doc.expiryDate.difference(now).inDays;
        if (daysDiff <= 20) {
          tasks.add(
            MaintenanceTask(
              id: 'tsk-${taskCounter.toString().padLeft(3, '0')}',
              vehicleId: vehicle.id,
              title: '${doc.type.label} Renewal (${vehicle.registrationNo})',
              dueDate: doc.expiryDate,
              isDone: false,
              scheduleId: 'sch-doc-${doc.id}',
            ),
          );
          taskCounter++;
        }
      }
    }

    return tasks;
  }

  static UserSettings defaultUserSettings = const UserSettings();
  static CompanySettings defaultCompanySettings = const CompanySettings();
}
