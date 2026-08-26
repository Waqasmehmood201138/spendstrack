/// One participant's owed share of an expense, in integer cents, plus the
/// raw split input that produced it (kept for [split_type] `percentage`/
/// `shares` so the expense can later be re-edited from its original inputs
/// rather than just its resolved dollar amounts — see docs/database-schema.md).
class ParticipantSplit {
  final String userId;
  final int owedCents;
  final double? percentage;
  final int? shares;

  const ParticipantSplit({
    required this.userId,
    required this.owedCents,
    this.percentage,
    this.shares,
  });
}

/// Thrown when split inputs don't reconcile to the expense total — surfaced
/// to the user as a form validation error before the request ever reaches
/// Supabase (which also enforces this server-side via a trigger, as a
/// backstop, not the primary UX).
class SplitValidationError implements Exception {
  final String message;
  const SplitValidationError(this.message);
  @override
  String toString() => message;
}

/// Equal split: `totalCents` divided evenly, any leftover cent(s) from
/// integer division go to the first N participants (largest-remainder
/// method degenerates to this when all weights are equal) so the total is
/// always exact — never off by a cent due to rounding.
List<ParticipantSplit> calculateEqualSplit({
  required int totalCents,
  required List<String> participantIds,
}) {
  if (participantIds.isEmpty) {
    throw const SplitValidationError('Select at least one person to split with.');
  }
  final base = totalCents ~/ participantIds.length;
  final remainder = totalCents - (base * participantIds.length);
  return [
    for (var i = 0; i < participantIds.length; i++)
      ParticipantSplit(userId: participantIds[i], owedCents: base + (i < remainder ? 1 : 0)),
  ];
}

/// Exact split: each participant's amount is given directly by the user.
/// Validates the amounts sum to the expense total instead of silently
/// adjusting anything.
List<ParticipantSplit> calculateExactSplit({
  required int totalCents,
  required Map<String, int> exactCentsByUser,
}) {
  if (exactCentsByUser.isEmpty) {
    throw const SplitValidationError('Select at least one person to split with.');
  }
  final sum = exactCentsByUser.values.fold<int>(0, (a, b) => a + b);
  if (sum != totalCents) {
    throw SplitValidationError(
      'Amounts add up to ${(sum / 100).toStringAsFixed(2)}, but the expense is ${(totalCents / 100).toStringAsFixed(2)}.',
    );
  }
  return exactCentsByUser.entries
      .map((e) => ParticipantSplit(userId: e.key, owedCents: e.value))
      .toList();
}

/// Percentage split: each participant's percentage of `totalCents`,
/// converted to cents via the largest-remainder method so the parts sum
/// exactly to the total despite per-participant rounding.
List<ParticipantSplit> calculatePercentageSplit({
  required int totalCents,
  required Map<String, double> percentageByUser,
}) {
  if (percentageByUser.isEmpty) {
    throw const SplitValidationError('Select at least one person to split with.');
  }
  final totalPercentage = percentageByUser.values.fold<double>(0, (a, b) => a + b);
  if ((totalPercentage - 100).abs() > 0.01) {
    throw SplitValidationError('Percentages add up to ${totalPercentage.toStringAsFixed(1)}%, not 100%.');
  }
  final weights = {for (final e in percentageByUser.entries) e.key: e.value};
  final owed = _distributeByWeight(totalCents, weights);
  return [
    for (final entry in percentageByUser.entries)
      ParticipantSplit(userId: entry.key, owedCents: owed[entry.key]!, percentage: entry.value),
  ];
}

/// Shares split (e.g. "2 shares for Alex, 1 share for Sam"): proportional to
/// each participant's share count, via the same largest-remainder method.
List<ParticipantSplit> calculateSharesSplit({
  required int totalCents,
  required Map<String, int> sharesByUser,
}) {
  if (sharesByUser.isEmpty) {
    throw const SplitValidationError('Select at least one person to split with.');
  }
  if (sharesByUser.values.any((s) => s <= 0)) {
    throw const SplitValidationError('Shares must be greater than zero.');
  }
  final weights = {for (final e in sharesByUser.entries) e.key: e.value.toDouble()};
  final owed = _distributeByWeight(totalCents, weights);
  return [
    for (final entry in sharesByUser.entries)
      ParticipantSplit(userId: entry.key, owedCents: owed[entry.key]!, shares: entry.value),
  ];
}

/// Validates that a set of payer amounts (single- or multi-payer) sums to
/// the expense total. Paid amounts are direct user input, not calculated —
/// this only checks reconciliation.
void validatePaidShares({required int totalCents, required Map<String, int> paidCentsByUser}) {
  if (paidCentsByUser.values.every((c) => c == 0)) {
    throw const SplitValidationError('Select who paid.');
  }
  final sum = paidCentsByUser.values.fold<int>(0, (a, b) => a + b);
  if (sum != totalCents) {
    throw SplitValidationError(
      'Paid amounts add up to ${(sum / 100).toStringAsFixed(2)}, but the expense is ${(totalCents / 100).toStringAsFixed(2)}.',
    );
  }
}

/// Distributes `totalCents` across `weights` proportionally, using the
/// largest-remainder method: floor each proportional share, then hand the
/// leftover cents (always < weights.length of them) to the entries with the
/// largest fractional remainder, breaking ties by iteration order for
/// determinism. Guarantees the result always sums exactly to `totalCents`.
Map<String, int> _distributeByWeight(int totalCents, Map<String, double> weights) {
  final totalWeight = weights.values.fold<double>(0, (a, b) => a + b);
  final raw = {for (final e in weights.entries) e.key: totalCents * e.value / totalWeight};
  final floored = {for (final e in raw.entries) e.key: e.value.floor()};
  var distributed = floored.values.fold<int>(0, (a, b) => a + b);
  var remaining = totalCents - distributed;

  final byRemainderDesc = raw.keys.toList()
    ..sort((a, b) => (raw[b]! - floored[b]!).compareTo(raw[a]! - floored[a]!));

  final result = Map<String, int>.from(floored);
  for (final key in byRemainderDesc) {
    if (remaining <= 0) break;
    result[key] = result[key]! + 1;
    remaining--;
  }
  return result;
}
