import 'package:bus_app/core/errors/app_exception.dart';
import 'package:bus_app/features/notifications/domain/app_notification.dart';
import 'package:bus_app/features/notifications/domain/notification_repository.dart';
import 'mock_delay.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications = [];

  MockNotificationRepository() {
    final now = DateTime.now();
    _notifications.addAll([
      AppNotification(
        id: 'notif-1',
        userId: 'usr-001',
        type: NotificationType.taskOverdue,
        title: 'PUC Expired: AP 28 Z 8844',
        body:
            'PUC certificate expired 4 days ago. Vehicle requires immediate emission test.',
        linkTarget: '/vehicles/veh-003',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'notif-2',
        userId: 'usr-001',
        type: NotificationType.serviceDue,
        title: 'Service Due Soon: TS 07 UA 1122',
        body: 'Annual Fitness Test due in 8 days.',
        linkTarget: '/vehicles/veh-002',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'notif-3',
        userId: 'usr-001',
        type: NotificationType.docExpiry,
        title: 'Insurance Policy Due: TS 07 UA 1122',
        body: 'Bajaj Allianz insurance policy renewal due in 18 days.',
        linkTarget: '/vehicles/veh-002',
        isRead: true,
        readAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  Future<List<AppNotification>> list(
      {String? userId, bool unreadOnly = false}) async {
    await MockDelay.simulate(minMs: 200, maxMs: 400);
    var result = _notifications;
    if (userId != null) {
      result = result.where((n) => n.userId == userId).toList();
    }
    if (unreadOnly) {
      result = result.where((n) => !n.isRead).toList();
    }
    return List.unmodifiable(result);
  }

  @override
  Future<int> unreadCount({String? userId}) async {
    await MockDelay.simulate(minMs: 100, maxMs: 250);
    return _notifications.where((n) {
      if (userId != null && n.userId != userId) return false;
      return !n.isRead;
    }).length;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (id == 'fail-id') {
      await MockDelay.simulate(
          shouldFail: true, failureMessage: 'Simulated mark-as-read failure.');
    }
    await MockDelay.simulate(minMs: 100, maxMs: 250);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw NotFoundException('Notification with ID $id not found.');
    }
    _notifications[index] = _notifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    await MockDelay.simulate(minMs: 150, maxMs: 300);
    for (int i = 0; i < _notifications.length; i++) {
      if (userId == null || _notifications[i].userId == userId) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<AppNotification> create(AppNotification notification) async {
    await MockDelay.simulate(minMs: 150, maxMs: 300);
    _notifications.insert(0, notification);
    return notification;
  }
}
