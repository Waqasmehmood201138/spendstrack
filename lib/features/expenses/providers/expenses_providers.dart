import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/comment_model.dart';
import '../data/expense_model.dart';
import '../data/expenses_repository.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(supabaseClientProvider));
});

final groupExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, groupId) {
  return ref.watch(expensesRepositoryProvider).watchGroupExpenses(groupId);
});

final friendExpensesProvider = FutureProvider.family<List<Expense>, String>((ref, friendId) {
  return ref.watch(expensesRepositoryProvider).getFriendExpenses(friendId);
});

final expenseByIdProvider = FutureProvider.family<Expense, String>((ref, expenseId) {
  return ref.watch(expensesRepositoryProvider).getExpense(expenseId);
});

final expenseCommentsProvider = StreamProvider.family<List<ExpenseComment>, String>((ref, expenseId) {
  return ref.watch(expensesRepositoryProvider).watchComments(expenseId);
});

final expenseSearchResultsProvider = FutureProvider.family<List<Expense>, String>((ref, query) {
  return ref.watch(expensesRepositoryProvider).search(query);
});
