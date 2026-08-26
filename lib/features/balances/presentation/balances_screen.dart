import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../expenses/presentation/settle_up_screen.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/balance_model.dart';
import '../domain/debt_simplifier.dart';
import '../providers/balances_providers.dart';

/// Full-screen Balances view for a group — an expandable row per member
/// ("X gets back $Y in total") with the simplified settle-up suggestions
/// that involve them nested underneath, matching Splitwise's own screen.
class BalancesScreen extends ConsumerWidget {
  final String groupId;
  const BalancesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final suggestions = ref.watch(groupSettlementSuggestionsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Balances')),
      body: AsyncValueWidget<List<UserBalance>>(
        value: balancesAsync,
        data: (balances) {
          final nonZero = balances.where((b) => !b.amount.isZero).toList();
          if (nonZero.isEmpty) {
            return const EmptyState(icon: Icons.check_circle_outline, title: 'Everyone is settled up');
          }
          return ListView(
            children: [
              for (final b in nonZero)
                _MemberBalanceExpansion(
                  groupId: groupId,
                  balance: b,
                  suggestions: suggestions.where((s) => s.fromUserId == b.userId || s.toUserId == b.userId).toList(),
                ),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Simplify debts is turned on in this group.', textAlign: TextAlign.center),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberBalanceExpansion extends ConsumerWidget {
  final String groupId;
  final UserBalance balance;
  final List<SettlementSuggestion> suggestions;

  const _MemberBalanceExpansion({required this.groupId, required this.balance, required this.suggestions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(profileByIdProvider(balance.userId));
    final name = nameAsync.valueOrNull?.fullName ?? '...';
    final isPositive = balance.amount.isPositive;

    return ExpansionTile(
      initiallyExpanded: true,
      leading: UserAvatar(pictureUrl: nameAsync.valueOrNull?.pictureUrl, displayName: name, radius: 18),
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          children: [
            TextSpan(text: '$name ${isPositive ? 'gets back' : 'owes'} '),
            TextSpan(
              text: '${balance.amount.abs.format()} ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive ? BalanceColors.positive(context) : BalanceColors.negative(context),
              ),
            ),
            const TextSpan(text: 'in total'),
          ],
        ),
      ),
      children: [
        for (final s in suggestions) _SuggestionRow(groupId: groupId, suggestion: s),
      ],
    );
  }
}

class _SuggestionRow extends ConsumerWidget {
  final String groupId;
  final SettlementSuggestion suggestion;
  const _SuggestionRow({required this.groupId, required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromName = ref.watch(profileByIdProvider(suggestion.fromUserId)).valueOrNull?.fullName ?? '...';
    final toName = ref.watch(profileByIdProvider(suggestion.toUserId)).valueOrNull?.fullName ?? '...';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              children: [
                TextSpan(text: '$fromName owes '),
                TextSpan(
                  text: suggestion.amount.format(),
                  style: TextStyle(color: BalanceColors.positive(context), fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' to $toName'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  // Push reminders need notification infrastructure (Firebase/
                  // APNs) that isn't wired up yet — see docs/features-roadmap.md.
                  // Being upfront here beats a silently-broken button.
                  const SnackBar(content: Text('Push reminders need notification setup — coming soon')),
                ),
                child: const Text('Remind'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettleUpScreen(
                    groupId: groupId,
                    fromUserId: suggestion.fromUserId,
                    fromDisplayName: fromName,
                    toUserId: suggestion.toUserId,
                    toDisplayName: toName,
                    currencyCode: suggestion.amount.currencyCode,
                    suggestedCents: suggestion.amount.cents,
                  ),
                )),
                child: const Text('Settle up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
