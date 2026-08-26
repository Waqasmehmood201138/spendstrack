import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/balance_model.dart';

/// Renders a list of per-currency [UserBalance]s as the compact "owes you
/// $12.50" / "you owe $8.00" line used on friends and groups list rows.
/// Multiple currencies render as multiple lines (never summed together —
/// see docs/database-schema.md on why balances stay per-currency).
class BalanceSummaryText extends StatelessWidget {
  final List<UserBalance> balances;
  final String owesYouPrefix;
  final String youOwePrefix;

  const BalanceSummaryText({
    super.key,
    required this.balances,
    required this.owesYouPrefix,
    required this.youOwePrefix,
  });

  @override
  Widget build(BuildContext context) {
    final nonZero = balances.where((b) => !b.amount.isZero).toList();
    if (nonZero.isEmpty) {
      return Text('settled up', style: TextStyle(color: BalanceColors.neutral(context)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: nonZero.map((b) {
        final isPositive = b.amount.isPositive;
        return Text(
          '${isPositive ? owesYouPrefix : youOwePrefix} ${b.amount.abs.format()}',
          style: TextStyle(
            color: isPositive ? BalanceColors.positive(context) : BalanceColors.negative(context),
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}
