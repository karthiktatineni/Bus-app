import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);
  final SupabaseClient _client;

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in before loading notifications.'));

  @override
  Future<List<AppNotification>> list(
      {String? userId, bool unreadOnly = false}) async {
    var query = _client.from('notifications').select().eq('user_id', _userId);
    if (unreadOnly) query = query.isFilter('read_at', null);
    final rows = await query.order('created_at', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> unreadCount({String? userId}) async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', _userId)
        .isFilter('read_at', null);
    return rows.length;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> markAllAsRead({String? userId}) async {
    await _client
        .from('notifications')
        .update({
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', _userId)
        .isFilter('read_at', null);
  }

  @override
  Future<AppNotification> create(AppNotification notification) async {
    final profile = await _client
        .from('profiles')
        .select('company_id')
        .eq('id', _userId)
        .single();
    final row = await _client
        .from('notifications')
        .insert({
          'company_id': profile['company_id'],
          'user_id': _userId,
          'type': notification.type.name,
          'title': notification.title,
          'body': notification.body,
          'link_target': notification.linkTarget,
        })
        .select()
        .single();
    return _fromRow(row);
  }

  AppNotification _fromRow(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        type: NotificationType.values.firstWhere(
            (type) => type.name == row['type'],
            orElse: () => NotificationType.general),
        title: row['title'] as String,
        body: row['body'] as String,
        linkTarget: row['link_target'] as String?,
        isRead: row['read_at'] != null,
        readAt: row['read_at'] == null
            ? null
            : DateTime.parse(row['read_at'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
