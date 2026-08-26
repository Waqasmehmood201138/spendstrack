import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../categories/providers/categories_providers.dart';
import '../../expenses/data/expense_model.dart';
import '../../expenses/presentation/expense_detail_screen.dart';
import '../../expenses/providers/expenses_providers.dart';

/// Splitwise Pro markets "expense search" as a paid feature; here it's just
/// a query against RLS-scoped data (every expense the signed-in user can
/// already see), so there's no reason to gate it — see docs/features-roadmap.md.
class ExpenseSearchScreen extends ConsumerStatefulWidget {
  const ExpenseSearchScreen({super.key});

  @override
  ConsumerState<ExpenseSearchScreen> createState() => _ExpenseSearchScreenState();
}

class _ExpenseSearchScreenState extends ConsumerState<ExpenseSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search expenses...',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
      ),
      body: _query.isEmpty
          ? const EmptyState(icon: Icons.search, title: 'Search by description')
          : Consumer(
              builder: (context, ref, _) {
                final resultsAsync = ref.watch(expenseSearchResultsProvider(_query));
                return AsyncValueWidget<List<Expense>>(
                  value: resultsAsync,
                  data: (results) {
                    if (results.isEmpty) {
                      return const EmptyState(icon: Icons.search_off, title: 'No matching expenses');
                    }
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final expense = results[index];
                        final category = ref.watch(categoryByIdProvider(expense.categoryId));
                        return ListTile(
                          leading: Icon(category?.icon ?? Icons.receipt_long),
                          title: Text(expense.description),
                          subtitle: Text(expense.cost.format()),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: expense.id)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
