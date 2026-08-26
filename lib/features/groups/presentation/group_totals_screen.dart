import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/group_model.dart';

/// Per-member paid/owed totals across the group's whole history — computed
/// client-side from the already-loaded expense stream.
class GroupTotalsScreen extends ConsumerWidget {
  final Group group;
  const GroupTotalsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Totals')),
      body: AsyncValueWidget<List<Expense>>(
        value: expensesAsync,
        data: (expenses) {
          final visible = expenses.where((e) => !e.isDeleted).toList();
          final paidByUser = <String, int>{};
          final owedByUser = <String, int>{};
          var currency = 'USD';
          for (final e in visible) {
            currency = e.cost.currencyCode;
            for (final u in e.users) {
              paidByUser[u.userId] = (paidByUser[u.userId] ?? 0) + u.paidCents;
              owedByUser[u.userId] = (owedByUser[u.userId] ?? 0) + u.owedCents;
            }
          }
          final totalSpent = visible.where((e) => !e.isPayment).fold<int>(0, (a, e) => a + e.cost.cents);
          final userIds = {...paidByUser.keys, ...owedByUser.keys}.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Total group spending', style: Theme.of(context).textTheme.bodyMedium),
              Text('$currency ${(totalSpent / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 40),
              for (final userId in userIds) _UserTotalRow(userId: userId, paidCents: paidByUser[userId] ?? 0, owedCents: owedByUser[userId] ?? 0, currency: currency),
            ],
          );
        },
      ),
    );
  }
}

class _UserTotalRow extends ConsumerWidget {
  final String userId;
  final int paidCents;
  final int owedCents;
  final String currency;
  const _UserTotalRow({required this.userId, required this.paidCents, required this.owedCents, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(userId)).valueOrNull;
    return ListTile(
      leading: UserAvatar(pictureUrl: profile?.pictureUrl, displayName: profile?.fullName ?? ''),
      title: Text(profile?.fullName ?? '...'),
      subtitle: Text('Paid $currency ${(paidCents / 100).toStringAsFixed(2)}'),
      trailing: Text('Owes $currency ${(owedCents / 100).toStringAsFixed(2)}'),
    );
  }
}
