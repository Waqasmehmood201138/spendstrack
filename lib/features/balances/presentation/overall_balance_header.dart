import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/balances_providers.dart';

/// "Overall, you are owed $X" banner shared by the Groups and Friends tabs
/// — matches Splitwise's own layout exactly, including the trailing sort
/// icon (here a no-op placeholder slot since neither tab currently exposes
/// a sort order to change).
class OverallBalanceHeader extends ConsumerWidget {
  const OverallBalanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(overallBalanceProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: balancesAsync.when(
        data: (balances) {
          final nonZero = balances.where((m) => !m.isZero).toList();
          if (nonZero.isEmpty) {
            return Text('You are all settled up', style: theme.textTheme.titleMedium);
          }
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final m in nonZero)
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                    children: [
                      TextSpan(text: m.isPositive ? 'Overall, you are owed ' : 'Overall, you owe '),
                      TextSpan(
                        text: m.abs.format(),
                        style: TextStyle(
                          color: m.isPositive ? BalanceColors.positive(context) : BalanceColors.negative(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '  '),
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const SizedBox(height: 24),
        error: (e, st) => const SizedBox.shrink(),
      ),
    );
  }
}
