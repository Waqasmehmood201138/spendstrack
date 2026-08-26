import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../balances/providers/balances_providers.dart';
import '../../search/presentation/expense_search_screen.dart';
import '../data/group_model.dart';
import '../providers/groups_providers.dart';
import 'create_group_dialog.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseSearchScreen()),
            ),
          ),
        ],
      ),
      body: AsyncValueWidget<List<Group>>(
        value: groupsAsync,
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.group_outlined,
              title: 'No groups yet',
              subtitle: 'Create a group for a trip, apartment, or anything you split regularly.',
              action: FilledButton.icon(
                onPressed: () async {
                  final id = await showCreateGroupDialog(context);
                  if (id != null && context.mounted) context.push('/groups/$id');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create a group'),
              ),
            );
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupListTile(group: group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await showCreateGroupDialog(context);
          if (id != null && context.mounted) context.push('/groups/$id');
        },
        child: const Icon(Icons.add),
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
    final myBalances = (balancesAsync.valueOrNull ?? const [])
        .where((b) => b.userId == myUserId)
        .toList();

    return ListTile(
      leading: CircleAvatar(child: Icon(group.groupType.icon)),
      title: Text(group.name),
      subtitle: BalanceSummaryText(
        balances: myBalances,
        owesYouPrefix: 'you are owed',
        youOwePrefix: 'you owe',
      ),
      onTap: () => context.push('/groups/${group.id}'),
    );
  }
}
