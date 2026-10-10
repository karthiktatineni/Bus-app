import '../../domain/models/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final vehicles = [
      Vehicle(
        id: '1',
        registration: 'TS 09 UB 4521',
        make: 'Ashok Leyland Viking',
        year: 2020,
        status: 'Overdue',
        nextMaintenance: '10 May 2024',
        odometerKm: 184200,
      ),
      Vehicle(
        id: '2',
        registration: 'KA 01 MJ 8820',
        make: 'Tata Starbus Ultra',
        year: 2022,
        status: 'Due soon',
        nextMaintenance: '25 May 2024',
        odometerKm: 92450,
      ),
      Vehicle(
        id: '3',
        registration: 'DL 01 AA 9022',
        make: 'Volvo 9600 Multi-Axle',
        year: 2023,
        status: 'Due soon',
        nextMaintenance: '15 Jul 2024',
        odometerKm: 312800,
      ),
      Vehicle(
        id: '4',
        registration: 'MH 14 TC 7712',
        make: 'Eicher Skyline Pro',
        year: 2021,
        status: 'In workshop',
        nextMaintenance: '28 Jun 2024',
        odometerKm: 120000,
      ),
    ];

    return DashboardData(
      overdueCount: 1,
      dueSoonCount: 3,
      workshopCount: 1,
      todos: [
        TodoItem(id: 't1', taskName: 'Engine oil & filter replacement', status: 'Overdue by 2 days', vehicleId: 'TS 09 UB 4521', details: 'Est. ₹4,850 • Bay 1'),
        TodoItem(id: 't2', taskName: 'Front brake pads inspection', status: 'Tomorrow', vehicleId: 'KA 01 MJ 8820', details: 'Wear rating < 20% • Bay 3'),
        TodoItem(id: 't3', taskName: 'Clutch plate calibration', status: 'In 5 days', vehicleId: 'MH 12 RN 3104', details: 'Scheduled PM 30k'),
        TodoItem(id: 't4', taskName: 'Air filter & HVAC clean', status: 'In 9 days', vehicleId: 'DL 01 AA 9022', details: 'Fleet hygiene check'),
      ],
      upcomingVehicles: vehicles.sublist(0, 3),
      allVehicles: vehicles,
    );
  }
}
