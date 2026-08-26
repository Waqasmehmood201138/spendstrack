/// Mirrors `public.notifications` and the Postgres `notification_type` enum.
/// Populated server-side by RPCs/triggers (see docs/database-schema.md) —
/// the client only ever reads and marks-read, never inserts directly.
enum NotificationType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  expenseUndeleted,
  commentAdded,
  addedToGroup,
  removedFromGroup,
  groupDeleted,
  groupUndeleted,
  groupSettingsChanged,
  addedAsFriend,
  removedAsFriend,
  debtSimplified;

  static NotificationType fromJson(String value) {
    final snakeToCamel = value.split('_').asMap().entries.map((e) {
      final word = e.value;
      return e.key == 0 ? word : word[0].toUpperCase() + word.substring(1);
    }).join();
    return NotificationType.values.firstWhere(
      (t) => t.name == snakeToCamel,
      orElse: () => NotificationType.expenseAdded,
    );
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String? actorId;
  final String sourceType;
  final String sourceId;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.sourceType,
    required this.sourceId,
    required this.content,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: NotificationType.fromJson(json['type'] as String),
        actorId: json['actor_id'] as String?,
        sourceType: json['source_type'] as String,
        sourceId: json['source_id'] as String,
        content: json['content'] as String,
        readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
