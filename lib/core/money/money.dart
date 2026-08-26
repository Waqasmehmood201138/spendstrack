import 'package:intl/intl.dart';

/// A monetary amount stored as integer cents to avoid floating-point drift in
/// split/debt-simplification math. Convert to/from Postgres `numeric` only at
/// the repository boundary via [Money.fromDecimal]/[toDecimal].
class Money {
  final int cents;
  final String currencyCode;

  const Money(this.cents, this.currencyCode);

  factory Money.fromDecimal(num amount, String currencyCode) =>
      Money((amount * 100).round(), currencyCode);

  double toDecimal() => cents / 100;

  Money operator +(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot add different currencies');
    return Money(cents + other.cents, currencyCode);
  }

  Money operator -(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot subtract different currencies');
    return Money(cents - other.cents, currencyCode);
  }

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;
  Money get abs => Money(cents.abs(), currencyCode);

  String format({String? locale}) {
    return NumberFormat.simpleCurrency(name: currencyCode, locale: locale).format(toDecimal());
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(cents, currencyCode);

  @override
  String toString() => format();
}

/// Splits [totalCents] into [count] integer-cent shares that sum back exactly
/// to [totalCents], distributing the rounding remainder across the first N
/// shares (largest-remainder method) so no cent is ever lost or invented.
List<int> distributeCentsEqually(int totalCents, int count) {
  assert(count > 0);
  final base = totalCents ~/ count;
  final remainder = totalCents - (base * count);
  return List.generate(count, (i) => base + (i < remainder ? 1 : 0));
}
