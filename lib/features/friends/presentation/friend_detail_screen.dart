import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/presentation/balance_summary_text.dart';
import '../../balances/providers/balances_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/presentation/settle_up_screen.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/friends_providers.dart';

class FriendDetailScreen extends ConsumerWidget {
  final String friendId;
  const FriendDetailScreen({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendAsync = ref.watch(profileByIdProvider(friendId));
    final balancesAsync = ref.watch(friendBalanceProvider(friendId));
    final expensesAsync = ref.watch(friendExpensesProvider(friendId));
    final me = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(friendAsync.valueOrNull?.fullName ?? 'Friend'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'remove') {
                await ref.read(friendsRepositoryProvider).removeFriend(friendId);
                if (context.mounted) context.pop();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                UserAvatar(
                  pictureUrl: friendAsync.valueOrNull?.pictureUrl,
                  displayName: friendAsync.valueOrNull?.fullName ?? '',
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AsyncValueWidget<List<UserBalance>>(
                    value: balancesAsync,
                    data: (balances) => BalanceSummaryText(
                      balances: balances,
                      owesYouPrefix: 'owes you',
                      youOwePrefix: 'you owe',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<Expense>>(
              value: expensesAsync,
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No shared expenses yet',
                  );
                }
                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final category = ref.watch(categoryByIdProvider(expense.categoryId));
                    final net = me == null ? 0 : expense.netFor(me).cents;
                    return ListTile(
                      leading: Icon(category?.icon ?? Icons.receipt_long),
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
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'settle-up',
            onPressed: () async {
              final friend = friendAsync.valueOrNull;
              final myProfile = ref.read(currentProfileProvider).valueOrNull;
              if (friend == null || myProfile == null || me == null) return;
              final balances = balancesAsync.valueOrNull ?? const [];
              final suggested = balances.isEmpty ? 0 : balances.first.amount.cents.abs();
              final currency = balances.isEmpty ? myProfile.defaultCurrency : balances.first.amount.currencyCode;
              final iOwe = balances.isNotEmpty && balances.first.amount.isNegative;
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettleUpScreen(
                  groupId: null,
                  fromUserId: iOwe ? me : friend.id,
                  fromDisplayName: iOwe ? 'You' : friend.fullName,
                  toUserId: iOwe ? friend.id : me,
                  toDisplayName: iOwe ? friend.fullName : 'You',
                  currencyCode: currency,
                  suggestedCents: suggested,
                ),
              ));
            },
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Settle up'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add-expense',
            onPressed: () {
              final myProfile = ref.read(currentProfileProvider).valueOrNull;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddExpenseScreen(
                  friendId: friendId,
                  currencyCode: myProfile?.defaultCurrency ?? 'USD',
                ),
              ));
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
