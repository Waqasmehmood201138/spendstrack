import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_model.dart';

class ActivityRepository {
  final SupabaseClient _client;
  const ActivityRepository(this._client);

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  Future<void> markRead(String notificationId) async {
    await _client.from('notifications').update({'read_at': DateTime.now().toIso8601String()}).eq('id', notificationId);
  }

  Future<void> markAllRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}
