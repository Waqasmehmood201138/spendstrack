import 'package:flutter_test/flutter_test.dart';
import 'package:spendstrack/features/expenses/domain/split_calculator.dart';

void main() {
  group('calculateEqualSplit', () {
    test('splits evenly when it divides cleanly', () {
      final splits = calculateEqualSplit(totalCents: 3000, participantIds: ['a', 'b', 'c']);
      expect(splits.map((s) => s.owedCents), [1000, 1000, 1000]);
    });

    test('distributes the remainder cent-by-cent so the total is always exact', () {
      final splits = calculateEqualSplit(totalCents: 1000, participantIds: ['a', 'b', 'c']);
      final total = splits.fold<int>(0, (sum, s) => sum + s.owedCents);
      expect(total, 1000);
      expect(splits.map((s) => s.owedCents).toSet(), {333, 334});
    });

    test('throws when there are no participants', () {
      expect(() => calculateEqualSplit(totalCents: 100, participantIds: []),
          throwsA(isA<SplitValidationError>()));
    });
  });

  group('calculateExactSplit', () {
    test('accepts amounts that sum to the total', () {
      final splits = calculateExactSplit(totalCents: 1000, exactCentsByUser: {'a': 600, 'b': 400});
      expect(splits.firstWhere((s) => s.userId == 'a').owedCents, 600);
    });

    test('rejects amounts that do not sum to the total', () {
      expect(
        () => calculateExactSplit(totalCents: 1000, exactCentsByUser: {'a': 600, 'b': 300}),
        throwsA(isA<SplitValidationError>()),
      );
    });
  });

  group('calculatePercentageSplit', () {
    test('splits proportionally and reconciles rounding via largest remainder', () {
      // 3-way split of $10.00 at 33.33% each doesn't divide evenly into cents.
      final splits = calculatePercentageSplit(
        totalCents: 1000,
        percentageByUser: {'a': 33.34, 'b': 33.33, 'c': 33.33},
      );
      final total = splits.fold<int>(0, (sum, s) => sum + s.owedCents);
      expect(total, 1000);
    });

    test('rejects percentages that do not sum to 100', () {
      expect(
        () => calculatePercentageSplit(totalCents: 1000, percentageByUser: {'a': 50, 'b': 40}),
        throwsA(isA<SplitValidationError>()),
      );
    });
  });

  group('calculateSharesSplit', () {
    test('splits proportionally to share counts', () {
      final splits = calculateSharesSplit(totalCents: 3000, sharesByUser: {'a': 2, 'b': 1});
      expect(splits.firstWhere((s) => s.userId == 'a').owedCents, 2000);
      expect(splits.firstWhere((s) => s.userId == 'b').owedCents, 1000);
    });

    test('reconciles rounding for share counts that do not divide evenly', () {
      final splits = calculateSharesSplit(totalCents: 1000, sharesByUser: {'a': 1, 'b': 1, 'c': 1});
      final total = splits.fold<int>(0, (sum, s) => sum + s.owedCents);
      expect(total, 1000);
    });

    test('rejects zero or negative shares', () {
      expect(
        () => calculateSharesSplit(totalCents: 1000, sharesByUser: {'a': 0, 'b': 2}),
        throwsA(isA<SplitValidationError>()),
      );
    });
  });

  group('validatePaidShares', () {
    test('accepts paid amounts that sum to the total', () {
      expect(
        () => validatePaidShares(totalCents: 1000, paidCentsByUser: {'a': 1000, 'b': 0}),
        returnsNormally,
      );
    });

    test('rejects paid amounts that do not sum to the total', () {
      expect(
        () => validatePaidShares(totalCents: 1000, paidCentsByUser: {'a': 900, 'b': 0}),
        throwsA(isA<SplitValidationError>()),
      );
    });

    test('rejects when nobody paid anything', () {
      expect(
        () => validatePaidShares(totalCents: 1000, paidCentsByUser: {'a': 0, 'b': 0}),
        throwsA(isA<SplitValidationError>()),
      );
    });
  });
}
