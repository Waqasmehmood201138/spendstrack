import 'package:supabase_flutter/supabase_flutter.dart';

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
}
