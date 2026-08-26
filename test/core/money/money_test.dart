import 'package:flutter_test/flutter_test.dart';
import 'package:spendstrack/core/money/money.dart';

void main() {
  group('Money', () {
    test('fromDecimal rounds to the nearest cent', () {
      expect(Money.fromDecimal(10.005, 'USD').cents, 1001);
      expect(Money.fromDecimal(9.999, 'USD').cents, 1000);
    });

    test('toDecimal round-trips fromDecimal', () {
      expect(Money.fromDecimal(19.99, 'USD').toDecimal(), 19.99);
    });

    test('addition and subtraction operate in cents', () {
      const a = Money(1000, 'USD');
      const b = Money(250, 'USD');
      expect((a + b).cents, 1250);
      expect((a - b).cents, 750);
    });
  });

  group('distributeCentsEqually', () {
    test('always sums back to the original total', () {
      for (final total in [0, 1, 99, 100, 1000, 12345]) {
        for (final count in [1, 2, 3, 7]) {
          final parts = distributeCentsEqually(total, count);
          expect(parts.fold<int>(0, (a, b) => a + b), total, reason: 'total=$total count=$count');
          expect(parts.length, count);
        }
      }
    });
  });
}
