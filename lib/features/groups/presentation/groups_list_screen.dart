import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../balances/presentation/overall_balance_header.dart';
import '../../balances/providers/balances_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../friends/presentation/add_friend_dialog.dart';
import '../../profile/providers/profile_providers.dart';
import '../../search/presentation/expense_search_screen.dart';
import 'group_avatar.dart';
import 'create_group_screen.dart';
import '../data/group_model.dart';
import '../providers/groups_providers.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
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
          const OverallBalanceHeader(),
          Expanded(
            child: AsyncValueWidget<List<Group>>(
              value: groupsAsync,
              data: (groups) => ListView(
                children: [
                  for (final group in groups) _GroupListTile(group: group),
                  const _NonGroupExpensesTile(),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final id = await showCreateGroupDialog(context);
                        if (id != null && context.mounted) context.push('/groups/$id');
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Start a new group'),
                    ),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Explicit heroTag: HomeShell's IndexedStack keeps every tab screen
        // mounted at once (not just the visible one), so this FAB and
        // FriendsListScreen's coexist in the tree simultaneously — without
        // distinct tags Flutter throws "multiple heroes share the same tag".
        heroTag: 'groups-add-expense-fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(currencyCode: myProfile?.defaultCurrency ?? 'USD'),
          ),
        ),
        icon: const Icon(Icons.receipt_long),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _GroupListTile extends ConsumerWidget {
  final Group group;
  const _GroupListTile({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(currentUserIdProvider);
    final balancesAsync = ref.watch(groupBalancesProvider(group.id));
    final myBalances = (balancesAsync.valueOrNull ?? const []).where((b) => b.userId == myUserId).toList();

    return ListTile(
      leading: GroupAvatar(seed: group.id, icon: group.groupType.icon),
      title: Text(group.name),
      subtitle: BalanceSummaryText(balances: myBalances, owesYouPrefix: 'you are owed', youOwePrefix: 'you owe'),
      onTap: () => context.push('/groups/${group.id}'),
    );
  }
}

class _NonGroupExpensesTile extends ConsumerWidget {
  const _NonGroupExpensesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(nonGroupBalanceProvider);
    final balances = balancesAsync.valueOrNull ?? const [];

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48 * 0.22),
          gradient: const LinearGradient(colors: [Color(0xFF0F5C56), Color(0xFF6B4A9C), Color(0xFFB5461D)]),
        ),
        child: const Icon(Icons.receipt_long, color: Colors.white),
      ),
      title: const Text('Non-group expenses'),
      subtitle: BalanceSummaryText(
        // Non-group expenses aren't tied to a single friend, so there's no
        // natural userId here — BalanceSummaryText never displays it, only
        // the amount, so a placeholder is fine.
        balances: [for (final m in balances) UserBalance(userId: 'non-group', amount: m)],
        owesYouPrefix: 'you are owed',
        youOwePrefix: 'you owe',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExpenseSearchScreen()),
      ),
    );
  }
}
