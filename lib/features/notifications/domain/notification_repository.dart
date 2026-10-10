import 'app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> list({String? userId, bool unreadOnly = false});
  Future<int> unreadCount({String? userId});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead({String? userId});
  Future<AppNotification> create(AppNotification notification);
}
