import 'package:flutter_test/flutter_test.dart';
import 'package:bus_app/features/services/domain/service_schedule.dart';
import 'package:bus_app/features/notifications/data/mock_notification_repository.dart';
import 'package:bus_app/mock/mock_delay.dart';

void main() {
  setUp(() {
    // Disable fake network latency during unit test suite for instant execution
    MockDelay.enableDelays = false;
  });

  tearDown(() {
    MockDelay.enableDelays = true;
  });

  group('ServiceSchedule & Due-Date/Due-KM Logic Tests', () {
    final baseDate = DateTime(2026, 10, 10);

    test('calculates nextDueDate and nextDueKm correctly from intervals', () {
      final schedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Engine Oil & Filter Service',
        intervalKm: 10000,
        intervalMonths: 3,
        lastDoneDate: DateTime(2026, 7, 10),
        lastDoneKm: 140000,
      );

      expect(schedule.nextDueKm, 150000);
      expect(schedule.nextDueDate, DateTime(2026, 10, 10));
    });

    test('due by date: triggered when date reached even if km not reached', () {
      final schedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Engine Oil Service',
        intervalKm: 10000,
        intervalMonths: 3,
        lastDoneDate: DateTime(2026, 7, 10),
        lastDoneKm: 140000, // next due km: 150000
      );

      // Current km is only 144000 (well below 150000), but date is 10 Oct 2026
      expect(
        schedule.isDue(currentOdometerKm: 144000, currentDate: baseDate),
        isTrue,
        reason: 'Should be due because 3 months have elapsed',
      );
      expect(schedule.daysRemaining(currentDate: baseDate), 0);
    });

    test('due by km: triggered when km reached even if date not arrived', () {
      final schedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Engine Oil Service',
        intervalKm: 10000,
        intervalMonths: 3,
        lastDoneDate: DateTime(2026, 9, 1), // next due date: 1 Dec 2026
        lastDoneKm: 140000, // next due km: 150000
      );

      // Current date is 10 Oct (almost 2 months early), but odometer hit 150200
      expect(
        schedule.isDue(currentOdometerKm: 150200, currentDate: baseDate),
        isTrue,
        reason: 'Should be due because km threshold was exceeded',
      );
      expect(schedule.kmRemaining(150200), -200);
    });

    test('whichever comes first rule verified', () {
      final schedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Brake Inspection',
        intervalKm: 20000,
        intervalMonths: 6,
        lastDoneDate: DateTime(2026, 5, 1),
        lastDoneKm: 100000,
      );

      // Case A: Neither date nor km reached
      expect(
        schedule.isDue(
            currentOdometerKm: 110000, currentDate: DateTime(2026, 8, 1)),
        isFalse,
      );

      // Case B: KM reached first (120,500 km) on August 1 (before November due date)
      expect(
        schedule.isDue(
            currentOdometerKm: 120500, currentDate: DateTime(2026, 8, 1)),
        isTrue,
      );

      // Case C: Date reached first (Nov 15) while km is only 112,000 km
      expect(
        schedule.isDue(
            currentOdometerKm: 112000, currentDate: DateTime(2026, 11, 15)),
        isTrue,
      );
    });

    test('overdue detection for both date and km', () {
      final schedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Air Filter Cleaning',
        intervalKm: 15000,
        intervalMonths: 4,
        lastDoneDate: DateTime(2026, 5, 10), // next due: 10 Sept 2026
        lastDoneKm: 100000, // next due km: 115000
      );

      // On 10 Oct 2026 (1 month late)
      expect(
        schedule.isOverdue(currentOdometerKm: 110000, currentDate: baseDate),
        isTrue,
      );

      // Odometer 116000 km (1000 km past threshold)
      expect(
        schedule.isOverdue(
            currentOdometerKm: 116000, currentDate: DateTime(2026, 7, 1)),
        isTrue,
      );
    });

    test('completed task advances cycle to next interval', () {
      final initialSchedule = ServiceSchedule(
        id: 'sch-1',
        vehicleId: 'veh-001',
        taskName: 'Engine Oil Service',
        intervalKm: 10000,
        intervalMonths: 3,
        lastDoneDate: DateTime(2026, 7, 10),
        lastDoneKm: 140000,
      );

      // Complete service on 10 Oct 2026 at 150,500 km
      final nextCycle = initialSchedule.cycleCompleted(
        completedDate: DateTime(2026, 10, 10),
        completedKm: 150500,
      );

      expect(nextCycle.lastDoneDate, DateTime(2026, 10, 10));
      expect(nextCycle.lastDoneKm, 150500);
      expect(nextCycle.nextDueKm, 160500);
      expect(nextCycle.nextDueDate, DateTime(2027, 1, 10));
      expect(
          nextCycle.isDue(
              currentOdometerKm: 150500, currentDate: DateTime(2026, 10, 10)),
          isFalse);
    });
  });

  group('AppNotification & MockNotificationRepository Tests', () {
    test('notification listing, unread counts, and mark as read', () async {
      final repo = MockNotificationRepository();

      final initialUnread = await repo.unreadCount(userId: 'usr-001');
      expect(initialUnread, greaterThan(0));

      final notifications =
          await repo.list(userId: 'usr-001', unreadOnly: true);
      expect(notifications, isNotEmpty);

      final firstId = notifications.first.id;
      await repo.markAsRead(firstId);

      final unreadAfter = await repo.unreadCount(userId: 'usr-001');
      expect(unreadAfter, initialUnread - 1);
    });
  });
}
