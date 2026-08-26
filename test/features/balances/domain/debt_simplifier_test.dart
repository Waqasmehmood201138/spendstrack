import 'package:flutter_test/flutter_test.dart';
import 'package:spendstrack/core/money/money.dart';
import 'package:spendstrack/features/balances/domain/debt_simplifier.dart';

NetBalance _balance(String userId, int cents) => NetBalance(userId, Money(cents, 'USD'));

void main() {
  group('simplifyDebts', () {
    test('returns nothing when everyone is already settled', () {
      final result = simplifyDebts([_balance('a', 0), _balance('b', 0)]);
      expect(result, isEmpty);
    });

    test('two-person case: one payment settles it', () {
      final result = simplifyDebts([_balance('a', 1000), _balance('b', -1000)]);
      expect(result, hasLength(1));
      expect(result.single.fromUserId, 'b');
      expect(result.single.toUserId, 'a');
      expect(result.single.amount.cents, 1000);
    });

    test('a three-person cycle collapses to two transactions instead of three', () {
      // a is owed 1000 by the group overall, b nets to zero, c owes 1000.
      // Naively, everyone settling with everyone they individually owe could
      // take 3 payments; simplification should never need more than
      // (participants - 1) transactions.
      final result = simplifyDebts([_balance('a', 1000), _balance('b', 0), _balance('c', -1000)]);
      expect(result.length, lessThanOrEqualTo(2));
      final totalToA = result.where((s) => s.toUserId == 'a').fold<int>(0, (sum, s) => sum + s.amount.cents);
      expect(totalToA, 1000);
    });

    test('every suggested settlement, once applied, zeroes out the original balances', () {
      final balances = [_balance('a', 1500), _balance('b', -500), _balance('c', -1000)];
      final suggestions = simplifyDebts(balances);

      final netAfter = <String, int>{for (final b in balances) b.userId: b.amount.cents};
      for (final s in suggestions) {
        netAfter[s.fromUserId] = netAfter[s.fromUserId]! + s.amount.cents;
        netAfter[s.toUserId] = netAfter[s.toUserId]! - s.amount.cents;
      }
      expect(netAfter.values.every((v) => v == 0), isTrue);
    });

    test('never produces more transactions than (participants - 1)', () {
      final balances = [
        _balance('a', 500),
        _balance('b', 300),
        _balance('c', -200),
        _balance('d', -100),
        _balance('e', -500),
      ];
      final suggestions = simplifyDebts(balances);
      expect(suggestions.length, lessThanOrEqualTo(balances.length - 1));
    });
  });
}
