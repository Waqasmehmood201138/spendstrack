import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../data/balance_model.dart';
import '../data/balances_repository.dart';
import '../domain/debt_simplifier.dart';

final balancesRepositoryProvider = Provider<BalancesRepository>((ref) {
  return BalancesRepository(ref.watch(supabaseClientProvider));
});

/// `group_member_balances` is a view, so it can't be streamed directly (see
/// BalancesRepository.getGroupBalances) — instead this re-fetches balances
/// every time [groupExpensesProvider]'s realtime `expenses` stream emits,
/// which keeps this feeling live without Realtime on the view itself.
final groupBalancesProvider = FutureProvider.family<List<UserBalance>, String>((ref, groupId) {
  ref.watch(groupExpensesProvider(groupId));
  return ref.watch(balancesRepositoryProvider).getGroupBalances(groupId);
});

final friendBalanceProvider = FutureProvider.family<List<UserBalance>, String>((ref, friendId) {
  return ref.watch(balancesRepositoryProvider).getFriendBalance(friendId);
});

/// Debt-simplification suggestions for a group, grouped by currency (see
/// [simplifyDebts]'s single-currency requirement) and flattened back into
/// one list since a group is rarely multi-currency in practice but the
/// underlying data model allows it.
final groupSettlementSuggestionsProvider =
    Provider.family<List<SettlementSuggestion>, String>((ref, groupId) {
  final balancesAsync = ref.watch(groupBalancesProvider(groupId));
  final balances = balancesAsync.valueOrNull;
  if (balances == null) return const [];

  final byCurrency = <String, List<NetBalance>>{};
  for (final b in balances) {
    byCurrency.putIfAbsent(b.amount.currencyCode, () => []).add(NetBalance(b.userId, b.amount));
  }
  return byCurrency.values.expand(simplifyDebts).toList();
});
