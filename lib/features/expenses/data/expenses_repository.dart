import 'package:supabase_flutter/supabase_flutter.dart';

import 'comment_model.dart';
import 'expense_model.dart';
import 'expense_user_model.dart';

const _expenseSelect = '*, expense_users(*)';

class ExpensesRepository {
  final SupabaseClient _client;
  const ExpensesRepository(this._client);

  /// Realtime `.stream()` can only watch a single table (no embedded
  /// resources), so this streams raw `expenses` rows for the group and
  /// merges in each expense's `expense_users` on every emission — the same
  /// pattern as [GroupsRepository.watchMembers].
  Stream<List<Expense>> watchGroupExpenses(String groupId) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('expense_date', ascending: false)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <Expense>[];
          final expenseIds = rows.map((r) => r['id'] as String).toList();
          final userRows = await _client.from('expense_users').select().inFilter('expense_id', expenseIds);
          final userRowsByExpense = <String, List<Map<String, dynamic>>>{};
          for (final row in userRows) {
            userRowsByExpense.putIfAbsent(row['expense_id'] as String, () => []).add(row);
          }
          return rows
              .map((r) => Expense.fromJson({...r, 'expense_users': userRowsByExpense[r['id']] ?? const []}))
              .toList();
        });
  }

  /// Direct (non-group) expenses shared with [friendId]. Supabase's realtime
  /// `.stream()` can't filter on an embedded table, so this is a plain fetch
  /// (re-run by the provider on pull-to-refresh) rather than a live stream —
  /// acceptable since friend-to-friend expenses change far less often than a
  /// group's activity feed.
  Future<List<Expense>> getFriendExpenses(String friendId) async {
    final currentUserId = _client.auth.currentUser!.id;
    final sharedExpenseIds = await _client
        .from('expense_users')
        .select('expense_id')
        .eq('user_id', friendId)
        .then((rows) => rows.map((r) => r['expense_id'] as String).toList());
    if (sharedExpenseIds.isEmpty) return const [];
    final rows = await _client
        .from('expenses')
        .select(_expenseSelect)
        .inFilter('id', sharedExpenseIds)
        .isFilter('group_id', null)
        .order('expense_date', ascending: false);
    return rows.map(Expense.fromJson).where((e) {
      // Defensive: only expenses where both the viewer and the friend are
      // participants (RLS already guarantees the viewer is; this guards
      // against a stale id list from a race with a just-deleted expense).
      return e.users.any((u) => u.userId == currentUserId) && e.users.any((u) => u.userId == friendId);
    }).toList();
  }

  Future<Expense> getExpense(String expenseId) async {
    final row = await _client.from('expenses').select(_expenseSelect).eq('id', expenseId).single();
    return Expense.fromJson(row);
  }

  Stream<List<ExpenseComment>> watchComments(String expenseId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('expense_id', expenseId)
        .order('created_at')
        .map((rows) => rows.map(ExpenseComment.fromJson).toList());
  }

  Future<List<Expense>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final rows = await _client
        .from('expenses')
        .select(_expenseSelect)
        .ilike('description', '%${query.trim()}%')
        .order('expense_date', ascending: false)
        .limit(50);
    return rows.map(Expense.fromJson).toList();
  }

  Future<String> createExpense({
    required String? groupId,
    required String description,
    String? details,
    required int totalCents,
    required String currencyCode,
    required int? categoryId,
    required String splitType,
    required bool isPayment,
    required DateTime expenseDate,
    required List<ExpenseUser> users,
  }) async {
    final id = await _client.rpc('create_expense', params: {
      'p_group_id': groupId,
      'p_description': description,
      'p_details': details,
      'p_cost': totalCents / 100,
      'p_currency_code': currencyCode,
      'p_category_id': categoryId,
      'p_split_type': splitType,
      'p_is_payment': isPayment,
      'p_expense_date': expenseDate.toIso8601String().split('T').first,
      'p_users': users.map((u) => u.toRpcJson()).toList(),
    });
    return id as String;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client.rpc('soft_delete_expense', params: {'p_expense_id': expenseId});
  }

  Future<void> addComment({required String expenseId, required String content}) async {
    await _client.from('comments').insert({
      'expense_id': expenseId,
      'user_id': _client.auth.currentUser!.id,
      'content': content,
    });
  }
}
