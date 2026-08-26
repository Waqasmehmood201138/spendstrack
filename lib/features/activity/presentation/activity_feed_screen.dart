import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../data/notification_model.dart';
import '../providers/activity_providers.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: userId == null
                ? null
                : () => ref.read(activityRepositoryProvider).markAllRead(userId),
          ),
        ],
      ),
      body: AsyncValueWidget<List<AppNotification>>(
        value: notificationsAsync,
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(icon: Icons.notifications_none, title: 'No activity yet');
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: CircleAvatar(child: Icon(_iconFor(n.type))),
                title: Text(n.content),
                subtitle: Text(_relativeTime(n.createdAt)),
                tileColor: n.isUnread
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                onTap: () {
                  ref.read(activityRepositoryProvider).markRead(n.id);
                  if (n.sourceType == 'expense') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: n.sourceId)),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.expenseAdded || NotificationType.expenseUpdated || NotificationType.expenseUndeleted =>
          Icons.receipt_long,
        NotificationType.expenseDeleted => Icons.delete_outline,
        NotificationType.commentAdded => Icons.comment_outlined,
        NotificationType.addedToGroup || NotificationType.groupUndeleted => Icons.group_add,
        NotificationType.removedFromGroup || NotificationType.groupDeleted => Icons.group_remove,
        NotificationType.groupSettingsChanged => Icons.settings_outlined,
        NotificationType.addedAsFriend => Icons.person_add_alt,
        NotificationType.removedAsFriend => Icons.person_remove_alt_1,
        NotificationType.debtSimplified => Icons.compress,
      };

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
