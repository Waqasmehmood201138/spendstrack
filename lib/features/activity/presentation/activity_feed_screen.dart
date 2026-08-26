import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../profile/providers/profile_providers.dart';
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
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: userId == null ? null : () => ref.read(activityRepositoryProvider).markAllRead(userId),
          ),
        ],
      ),
      body: AsyncValueWidget<List<AppNotification>>(
        value: notificationsAsync,
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(icon: Icons.image_outlined, title: 'No activity yet');
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Recent activity', style: Theme.of(context).textTheme.headlineSmall),
              ),
              for (final n in notifications) _ActivityRow(notification: n),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  final AppNotification notification;
  const _ActivityRow({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorProfile = notification.actorId == null ? null : ref.watch(profileByIdProvider(notification.actorId!)).valueOrNull;
    final isDeleted = notification.type == NotificationType.expenseDeleted;

    return ListTile(
      leading: _OverlaidIcon(icon: _iconFor(notification.type), actorPictureUrl: actorProfile?.pictureUrl, actorName: actorProfile?.fullName ?? ''),
      title: Text(
        notification.content,
        style: isDeleted ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
      ),
      subtitle: Text(_relativeTime(notification.createdAt)),
      tileColor: notification.isUnread ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
      onTap: () {
        ref.read(activityRepositoryProvider).markRead(notification.id);
        if (notification.sourceType == 'expense') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: notification.sourceId)),
          );
        }
      },
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

/// A square icon badge with the acting user's avatar overlapping its
/// bottom-right corner — mirrors Splitwise's own activity-row treatment.
class _OverlaidIcon extends StatelessWidget {
  final IconData icon;
  final String? actorPictureUrl;
  final String actorName;

  const _OverlaidIcon({required this.icon, required this.actorPictureUrl, required this.actorName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (actorName.isNotEmpty)
            Positioned(
              right: -4,
              bottom: -4,
              child: UserAvatar(pictureUrl: actorPictureUrl, displayName: actorName, radius: 12),
            ),
        ],
      ),
    );
  }
}
