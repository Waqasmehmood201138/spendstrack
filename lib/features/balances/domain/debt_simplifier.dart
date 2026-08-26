import '../../../core/money/money.dart';

/// One person's net position in a single currency: positive means they are
/// owed money overall, negative means they owe money overall.
class NetBalance {
  final String userId;
  final Money amount;
  const NetBalance(this.userId, this.amount);
}

/// A suggested settle-up transaction produced by [simplifyDebts].
class SettlementSuggestion {
  final String fromUserId;
  final String toUserId;
  final Money amount;
  const SettlementSuggestion({required this.fromUserId, required this.toUserId, required this.amount});
}

/// Minimizes the number of settle-up transactions needed to zero out a set
/// of net balances, via the classic greedy match: repeatedly pair the
/// largest creditor with the largest debtor. Pure and currency-agnostic —
/// callers must pass balances already grouped by a single currency (mixing
/// currencies here would silently produce nonsense).
///
/// This is the "simplify debts" Splitwise itself offers per group
/// (`simplify_by_default` / `simplified_debts` in their API): instead of
/// everyone settling with everyone they individually owe, the group settles
/// with the fewest possible payments overall.
List<SettlementSuggestion> simplifyDebts(List<NetBalance> balances) {
  final nonZero = balances.where((b) => !b.amount.isZero).toList();
  if (nonZero.isEmpty) return const [];
  final currencyCode = nonZero.first.amount.currencyCode;
  assert(
    nonZero.every((b) => b.amount.currencyCode == currencyCode),
    'simplifyDebts requires all balances to share one currency',
  );

  final creditors = nonZero.where((b) => b.amount.isPositive).map((b) => (id: b.userId, cents: b.amount.cents)).toList()
    ..sort((a, b) => b.cents.compareTo(a.cents));
  final debtors = nonZero.where((b) => b.amount.isNegative).map((b) => (id: b.userId, cents: -b.amount.cents)).toList()
    ..sort((a, b) => b.cents.compareTo(a.cents));

  final result = <SettlementSuggestion>[];
  var ci = 0, di = 0;
  var creds = List.of(creditors);
  var debts = List.of(debtors);

  while (ci < creds.length && di < debts.length) {
    final settleCents = creds[ci].cents < debts[di].cents ? creds[ci].cents : debts[di].cents;
    if (settleCents > 0) {
      result.add(SettlementSuggestion(
        fromUserId: debts[di].id,
        toUserId: creds[ci].id,
        amount: Money(settleCents, currencyCode),
      ));
    }
    creds[ci] = (id: creds[ci].id, cents: creds[ci].cents - settleCents);
    debts[di] = (id: debts[di].id, cents: debts[di].cents - settleCents);
    if (creds[ci].cents == 0) ci++;
    if (debts[di].cents == 0) di++;
  }
  return result;
}
