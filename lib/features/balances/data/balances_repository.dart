import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/money/money.dart';
import 'balance_model.dart';

class BalancesRepository {
  final SupabaseClient _client;
  const BalancesRepository(this._client);

  /// A plain fetch, not `.stream()`: `group_member_balances` is a view, and
  /// Postgres logical replication — what Supabase Realtime is built on —
  /// only supports tables, so a view can never be subscribed to directly.
  /// `groupBalancesProvider` (balances_providers.dart) re-runs this whenever
  /// the group's `expenses` stream (a real table, realtime-capable) emits,
  /// which keeps balances live without needing Realtime on the view.
  Future<List<UserBalance>> getGroupBalances(String groupId) async {
    final rows = await _client.from('group_member_balances').select().eq('group_id', groupId);
    return rows.map(UserBalance.fromGroupBalanceJson).toList();
  }

  /// Every friend's net balance with the current user, across all currencies
  /// and both group and non-group expenses combined per friend — used for
  /// the friends list's "owes you $x" / "you owe $x" summary.
  Future<List<UserBalance>> getAllFriendBalances() async {
    final rows = await _client.from('friend_balances').select();
    return rows.map(UserBalance.fromFriendBalanceJson).toList();
  }

  Future<List<UserBalance>> getFriendBalance(String friendId) async {
    final rows = await _client.from('friend_balances').select().eq('friend_id', friendId);
    return rows.map(UserBalance.fromFriendBalanceJson).toList();
  }

  /// The signed-in user's net position across every expense they're a
  /// participant in — group and direct combined, every currency they've
  /// ever used — powering the "Overall, you are owed/owe X" header shared
  /// by the Groups and Friends tabs. Summed client-side from raw
  /// `expense_users` rows rather than a dedicated view, since it's a small,
  /// per-user dataset and RLS already scopes it correctly.
  Future<List<Money>> getOverallBalance(String userId) async {
    final rows = await _client
        .from('expense_users')
        .select('paid_share, owed_share, expenses!inner(currency_code, deleted_at)')
        .eq('user_id', userId);

    final totals = <String, int>{};
    for (final row in rows) {
      final expense = row['expenses'] as Map<String, dynamic>;
      if (expense['deleted_at'] != null) continue;
      final currencyCode = expense['currency_code'] as String;
      final netCents = (((row['paid_share'] as num) - (row['owed_share'] as num)) * 100).round();
      totals[currencyCode] = (totals[currencyCode] ?? 0) + netCents;
    }
    return totals.entries.map((e) => Money(e.value, e.key)).toList();
  }

  /// The user's net position across only their direct (non-group) expenses
  /// — powers the "Non-group expenses" pseudo-group row on the Groups tab,
  /// matching Splitwise's own layout.
  Future<List<Money>> getNonGroupBalance(String userId) async {
    final rows = await _client
        .from('expense_users')
        .select('paid_share, owed_share, expenses!inner(currency_code, deleted_at, group_id)')
        .eq('user_id', userId);

    final totals = <String, int>{};
    for (final row in rows) {
      final expense = row['expenses'] as Map<String, dynamic>;
      if (expense['deleted_at'] != null || expense['group_id'] != null) continue;
      final currencyCode = expense['currency_code'] as String;
      final netCents = (((row['paid_share'] as num) - (row['owed_share'] as num)) * 100).round();
      totals[currencyCode] = (totals[currencyCode] ?? 0) + netCents;
    }
    return totals.entries.map((e) => Money(e.value, e.key)).toList();
  }
}
