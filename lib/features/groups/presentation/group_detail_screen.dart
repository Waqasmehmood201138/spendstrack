import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/domain/debt_simplifier.dart';
import '../../balances/providers/balances_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/presentation/settle_up_screen.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/groups_providers.dart';
import 'add_member_dialog.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(groupAsync.valueOrNull?.name ?? 'Group'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'add_member':
                    await showAddMemberDialog(context, groupId);
                  case 'invite_link':
                    final group = groupAsync.valueOrNull;
                    if (group != null) {
                      await Clipboard.setData(ClipboardData(text: 'spendstrack://join/${group.inviteToken}'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Invite link copied')));
                      }
                    }
                  case 'leave':
                    final myUserId = ref.read(currentUserIdProvider);
                    if (myUserId != null) {
                      await ref.read(groupsRepositoryProvider).leaveGroup(groupId, myUserId);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'add_member', child: Text('Add member')),
                PopupMenuItem(value: 'invite_link', child: Text('Copy invite link')),
                PopupMenuItem(value: 'leave', child: Text('Leave group')),
              ],
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Balances'), Tab(text: 'Activity')]),
        ),
        body: TabBarView(
          children: [
            _BalancesTab(groupId: groupId),
            _ActivityTab(groupId: groupId),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final myProfile = ref.read(currentProfileProvider).valueOrNull;
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                groupId: groupId,
                currencyCode: myProfile?.defaultCurrency ?? 'USD',
              ),
            ));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final String groupId;
  const _BalancesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final suggestions = ref.watch(groupSettlementSuggestionsProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);

    return AsyncValueWidget<List<UserBalance>>(
      value: balancesAsync,
      data: (balances) {
        if (balances.every((b) => b.amount.isZero)) {
          return const EmptyState(icon: Icons.check_circle_outline, title: 'Everyone is settled up');
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Balances', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...balances.where((b) => !b.amount.isZero).map((b) => _MemberBalanceTile(balance: b)),
            if (suggestions.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Settle up suggestions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...suggestions.map((s) => _SuggestionTile(groupId: groupId, suggestion: s, myUserId: myUserId)),
            ],
          ],
        );
      },
    );
  }
}

class _MemberBalanceTile extends ConsumerWidget {
  final UserBalance balance;
  const _MemberBalanceTile({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(balance.userId));
    final name = profileAsync.valueOrNull?.fullName ?? '...';
    final isPositive = balance.amount.isPositive;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(pictureUrl: profileAsync.valueOrNull?.pictureUrl, displayName: name, radius: 16),
      title: Text(name),
      trailing: Text(
        '${isPositive ? 'gets back' : 'owes'} ${balance.amount.abs.format()}',
        style: TextStyle(
          color: isPositive ? Colors.green : Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SuggestionTile extends ConsumerWidget {
  final String groupId;
  final SettlementSuggestion suggestion;
  final String? myUserId;
  const _SuggestionTile({required this.groupId, required this.suggestion, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromAsync = ref.watch(profileByIdProvider(suggestion.fromUserId));
    final toAsync = ref.watch(profileByIdProvider(suggestion.toUserId));
    final fromName = fromAsync.valueOrNull?.fullName ?? '...';
    final toName = toAsync.valueOrNull?.fullName ?? '...';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_forward),
      title: Text('$fromName pays $toName ${suggestion.amount.format()}'),
      trailing: (myUserId == suggestion.fromUserId || myUserId == suggestion.toUserId)
          ? TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettleUpScreen(
                  groupId: groupId,
                  fromUserId: suggestion.fromUserId,
                  fromDisplayName: fromName,
                  toUserId: suggestion.toUserId,
                  toDisplayName: toName,
                  currencyCode: suggestion.amount.currencyCode,
                  suggestedCents: suggestion.amount.cents,
                ),
              )),
              child: const Text('Settle'),
            )
          : null,
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  final String groupId;
  const _ActivityTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);

    return AsyncValueWidget<List<Expense>>(
      value: expensesAsync,
      data: (expenses) {
        final visible = expenses.where((e) => !e.isDeleted).toList();
        if (visible.isEmpty) {
          return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet');
        }
        return ListView.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final expense = visible[index];
            final category = ref.watch(categoryByIdProvider(expense.categoryId));
            final net = myUserId == null ? 0 : expense.netFor(myUserId).cents;
            return ListTile(
              leading: Icon(expense.isPayment ? Icons.handshake_outlined : (category?.icon ?? Icons.receipt_long)),
              title: Text(expense.description),
              subtitle: Text(expense.cost.format()),
              trailing: net == 0
                  ? null
                  : Text(
                      '${net > 0 ? '+' : ''}${(net / 100).toStringAsFixed(2)}',
                      style: TextStyle(color: net > 0 ? Colors.green : Theme.of(context).colorScheme.error),
                    ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: expense.id)),
              ),
            );
          },
        );
      },
    );
  }
}
