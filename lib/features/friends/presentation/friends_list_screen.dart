import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../profile/data/profile_model.dart';
import '../providers/friends_providers.dart';
import 'add_friend_dialog.dart';

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final balancesByFriendAsync = ref.watch(allFriendBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: AsyncValueWidget<List<Profile>>(
        value: friendsAsync,
        data: (friends) {
          if (friends.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No friends yet',
              subtitle: 'Add a friend by email to start splitting expenses with them.',
              action: FilledButton.icon(
                onPressed: () => showAddFriendDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add a friend'),
              ),
            );
          }
          final balancesByFriend = balancesByFriendAsync.valueOrNull ?? const {};
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final balances = balancesByFriend[friend.id] ?? const [];
              return ListTile(
                leading: UserAvatar(pictureUrl: friend.pictureUrl, displayName: friend.fullName),
                title: Text(friend.fullName),
                subtitle: BalanceSummaryText(balances: balances, owesYouPrefix: 'owes you', youOwePrefix: 'you owe'),
                onTap: () => context.push('/friends/${friend.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddFriendDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
