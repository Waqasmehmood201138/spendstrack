import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../balances/providers/balances_providers.dart';
import '../../categories/presentation/category_picker.dart';
import '../../categories/providers/categories_providers.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/presentation/select_balance_to_settle_screen.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../profile/providers/profile_providers.dart';
import 'group_avatar.dart';
import 'group_charts_screen.dart';
import 'group_export.dart';
import 'group_settings_screen.dart';
import 'group_totals_screen.dart';
import 'group_whiteboard_screen.dart';
import '../../balances/presentation/balances_screen.dart';
import '../data/group_model.dart';
import '../providers/groups_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final memberCount = membersAsync.valueOrNull?.length ?? 0;

    return AsyncValueWidget<Group>(
      value: groupAsync,
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (group) {
        return Scaffold(
          body: Column(
            children: [
              _HeroHeader(group: group, memberCount: memberCount),
              _BalanceHeadline(groupId: groupId),
              _ChipRow(group: group),
              const Divider(height: 1),
              Expanded(child: _ExpenseList(groupId: groupId)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'group-detail-add-expense-fab',
            onPressed: () {
              final myProfile = ref.read(currentProfileProvider).valueOrNull;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddExpenseScreen(groupId: groupId, currencyCode: myProfile?.defaultCurrency ?? 'USD'),
              ));
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Group group;
  final int memberCount;
  const _HeroHeader({required this.group, required this.memberCount});

  @override
  Widget build(BuildContext context) {
    final gradient = groupHeroGradient(group.id);
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
              _CircleIconButton(
                icon: Icons.settings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GroupSettingsScreen(groupId: group.id)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('$memberCount people', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.black87, size: 20)),
      ),
    );
  }
}

class _BalanceHeadline extends ConsumerWidget {
  final String groupId;
  const _BalanceHeadline({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);

    final balances = balancesAsync.valueOrNull;
    if (balances == null) return const SizedBox(height: 56);
    final mine = balances.where((b) => b.userId == myUserId).toList();
    final nonZero = mine.where((b) => !b.amount.isZero).toList();

    if (nonZero.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text('Everyone is settled up'));
    }

    final memberCount = membersAsync.valueOrNull?.length ?? 0;
    String prefix = 'Overall, you';
    if (memberCount == 2) {
      final other = membersAsync.valueOrNull!.firstWhere((m) => m.userId != myUserId, orElse: () => membersAsync.valueOrNull!.first);
      prefix = nonZero.first.amount.isPositive ? '${other.fullName} owes you' : 'You owe ${other.fullName}';
    } else {
      prefix = nonZero.first.amount.isPositive ? 'Overall, you are owed' : 'Overall, you owe';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          children: [
            TextSpan(text: '$prefix '),
            TextSpan(
              text: nonZero.first.amount.abs.format(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: nonZero.first.amount.isPositive ? BalanceColors.positive(context) : BalanceColors.negative(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends ConsumerWidget {
  final Group group;
  const _ChipRow({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, 'Settle up', () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SelectBalanceToSettleScreen(groupId: group.id)))),
          _chip(context, 'Charts', () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GroupChartsScreen(group: group)))),
          _chip(context, 'Balances', () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BalancesScreen(groupId: group.id)))),
          _chip(context, 'Totals', () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GroupTotalsScreen(group: group)))),
          _chip(context, 'Whiteboard', () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GroupWhiteboardScreen(group: group)))),
          _chip(context, 'Export', () async {
            final list = ref.read(groupExpensesProvider(group.id)).valueOrNull ?? const <Expense>[];
            await showGroupExportDialog(context, group.name, list);
          }),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  final String groupId;
  const _ExpenseList({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);

    return AsyncValueWidget<List<Expense>>(
      value: expensesAsync,
      data: (expenses) {
        final visible = expenses.where((e) => !e.isDeleted).toList();
        if (visible.isEmpty) {
          return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses yet');
        }
        return ListView.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final expense = visible[index];
            final category = ref.watch(categoryByIdProvider(expense.categoryId));
            final net = myUserId == null ? 0 : expense.netFor(myUserId).cents;
            final myShare = myUserId == null ? null : expense.users.where((u) => u.userId == myUserId);
            final iPaid = myShare != null && myShare.isNotEmpty ? myShare.first.paidCents : 0;

            return ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DateBadge(date: expense.expenseDate),
                  const SizedBox(width: 8),
                  expense.isPayment
                      ? const Icon(Icons.handshake_outlined)
                      : CategoryIcon(category: category, size: 36),
                ],
              ),
              title: Text(expense.description),
              subtitle: Text(
                expense.isPayment
                    ? ''
                    : (iPaid > 0 ? 'You paid ${(iPaid / 100).toStringAsFixed(2)}' : ''),
              ),
              trailing: net == 0
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          net > 0 ? 'you lent' : 'you borrowed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          (net.abs() / 100).toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: net > 0 ? BalanceColors.positive(context) : BalanceColors.negative(context),
                          ),
                        ),
                      ],
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

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          Text(_months[date.month - 1], style: Theme.of(context).textTheme.bodySmall),
          Text('${date.day}', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
