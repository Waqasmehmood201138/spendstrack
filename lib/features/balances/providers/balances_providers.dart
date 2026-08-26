import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
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

/// Powers the "Overall, you are owed/owe X" header shared by the Groups and
/// Friends tabs. There's no single realtime stream spanning every group and
/// friend an expense could touch, so this doesn't auto-refresh like
/// [groupBalancesProvider] does — instead, call sites that create an expense
/// or settlement explicitly `ref.invalidate(overallBalanceProvider)` after
/// success (see AddExpenseScreen, SettleUpScreen).
final overallBalanceProvider = FutureProvider<List<Money>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(balancesRepositoryProvider).getOverallBalance(userId);
});

/// Backs the "Non-group expenses" row on the Groups tab. Same invalidation
/// caveat as [overallBalanceProvider] — no single realtime stream to hook.
final nonGroupBalanceProvider = FutureProvider<List<Money>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(balancesRepositoryProvider).getNonGroupBalance(userId);
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
