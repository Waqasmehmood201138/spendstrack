/// Mirrors a `public.expense_users` row: one participant's paid/owed shares
/// of an expense. Combining both on one row (rather than a separate
/// "who paid" column plus a splits table) is what natively supports
/// multi-payer expenses — see docs/database-schema.md.
class ExpenseUser {
  final String userId;
  final int paidCents;
  final int owedCents;
  final double? percentage;
  final int? shares;

  const ExpenseUser({
    required this.userId,
    required this.paidCents,
    required this.owedCents,
    this.percentage,
    this.shares,
  });

  /// Positive = this user is owed money by the rest of the group for this
  /// expense; negative = this user owes money for it.
  int get netCents => paidCents - owedCents;

  factory ExpenseUser.fromJson(Map<String, dynamic> json) => ExpenseUser(
        userId: json['user_id'] as String,
        paidCents: ((json['paid_share'] as num) * 100).round(),
        owedCents: ((json['owed_share'] as num) * 100).round(),
        percentage: (json['percentage'] as num?)?.toDouble(),
        shares: json['shares'] as int?,
      );

  Map<String, dynamic> toRpcJson() => {
        'user_id': userId,
        'paid_share': paidCents / 100,
        'owed_share': owedCents / 100,
        'percentage': percentage,
        'shares': shares,
      };
}
