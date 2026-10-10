import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/notification_repository.dart';
import 'data/mock_notification_repository.dart';

export 'domain/app_notification.dart';
export 'domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});
