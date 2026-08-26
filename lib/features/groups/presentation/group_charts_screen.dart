import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../data/group_model.dart';

/// Group spending over the last 3 months — a free feature here (Splitwise
/// gates deeper chart drill-down behind Pro; per this project's scope, see
/// docs/features-roadmap.md, everything the schema can answer is unlocked).
/// Computed client-side from the group's already-loaded expense stream, no
/// extra query needed.
class GroupChartsScreen extends ConsumerWidget {
  final Group group;
  const GroupChartsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));
    final myUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: AsyncValueWidget<List<Expense>>(
        value: expensesAsync,
        data: (expenses) {
          final visible = expenses.where((e) => !e.isDeleted && !e.isPayment).toList();
          final now = DateTime.now();
          final months = List.generate(3, (i) => DateTime(now.year, now.month - 2 + i));
          final totalsByMonth = <DateTime, int>{
            for (final m in months) m: 0,
          };
          var myShareTotal = 0;
          final currency = visible.isNotEmpty ? visible.first.cost.currencyCode : 'USD';
          for (final e in visible) {
            final key = DateTime(e.expenseDate.year, e.expenseDate.month);
            if (totalsByMonth.containsKey(key)) {
              totalsByMonth[key] = totalsByMonth[key]! + e.cost.cents;
            }
            if (myUserId != null) {
              final mine = e.users.where((u) => u.userId == myUserId);
              if (mine.isNotEmpty) myShareTotal += mine.first.owedCents;
            }
          }
          final maxCents = totalsByMonth.values.fold<int>(1, (a, b) => a > b ? a : b);
          final totalSpentCents = totalsByMonth.values.fold<int>(0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${group.name} group spending', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final m in months)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 40,
                            height: 140 * (totalsByMonth[m]! / maxCents),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_monthLabel(m.month)),
                        ],
                      ),
                  ],
                ),
              ),
              const Divider(height: 48),
              Text('Total spent', style: Theme.of(context).textTheme.bodyMedium),
              Text('$currency ${(totalSpentCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Your share', style: Theme.of(context).textTheme.bodyMedium),
              Text('$currency ${(myShareTotal / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (totalSpentCents > 0)
                Text('${(myShareTotal / totalSpentCents * 100).toStringAsFixed(0)}% of total group spending'),
            ],
          );
        },
      ),
    );
  }

  String _monthLabel(int month) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
}
