import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../balances/presentation/overall_balance_header.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../../search/presentation/expense_search_screen.dart';
import '../providers/friends_providers.dart';
import 'add_friend_dialog.dart';

enum _FriendsFilter { all, outstanding, youOwe, owedToYou }

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  _FriendsFilter _filter = _FriendsFilter.all;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final balancesByFriendAsync = ref.watch(allFriendBalancesProvider);
    final myProfile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpenseSearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => showAddFriendDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              const Expanded(child: OverallBalanceHeader()),
              PopupMenuButton<_FriendsFilter>(
                icon: const Icon(Icons.tune),
                initialValue: _filter,
                onSelected: (f) => setState(() => _filter = f),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _FriendsFilter.all, child: Text('All friends')),
                  PopupMenuItem(value: _FriendsFilter.outstanding, child: Text('Outstanding balances')),
                  PopupMenuItem(value: _FriendsFilter.youOwe, child: Text('Friends you owe')),
                  PopupMenuItem(value: _FriendsFilter.owedToYou, child: Text('Friends who owe you')),
                ],
              ),
            ],
          ),
          Expanded(
            child: AsyncValueWidget<List<Profile>>(
              value: friendsAsync,
              data: (friends) {
                final balancesByFriend = balancesByFriendAsync.valueOrNull ?? const {};
                final visible = friends.where((f) => _matchesFilter(f.id, balancesByFriend)).toList();

                if (friends.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'No friends yet',
                    subtitle: 'Add a friend by email to start splitting expenses with them.',
                    action: FilledButton.icon(
                      onPressed: () => showAddFriendDialog(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add a friend'),
                    ),
                  );
                }

                return ListView(
                  children: [
                    for (final friend in visible)
                      ListTile(
                        leading: UserAvatar(pictureUrl: friend.pictureUrl, displayName: friend.fullName),
                        title: Text(friend.fullName),
                        subtitle: BalanceSummaryText(
                          balances: balancesByFriend[friend.id] ?? const [],
                          owesYouPrefix: 'owes you',
                          youOwePrefix: 'you owe',
                        ),
                        onTap: () => context.push('/friends/${friend.id}'),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => showAddFriendDialog(context),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add more friends'),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'friends-add-expense-fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(currencyCode: myProfile?.defaultCurrency ?? 'USD')),
        ),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Add expense'),
      ),
    );
  }

  bool _matchesFilter(String friendId, Map<String, List<UserBalance>> balancesByFriend) {
    if (_filter == _FriendsFilter.all) return true;
    final balances = balancesByFriend[friendId] ?? const [];
    final positive = balances.any((b) => b.amount.isPositive);
    final negative = balances.any((b) => b.amount.isNegative);
    return switch (_filter) {
      _FriendsFilter.outstanding => positive || negative,
      _FriendsFilter.youOwe => negative,
      _FriendsFilter.owedToYou => positive,
      _FriendsFilter.all => true,
    };
  }
}
