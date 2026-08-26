import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../balances/data/balance_model.dart';
import '../../balances/domain/debt_simplifier.dart';
import '../../balances/providers/balances_providers.dart';
import '../../profile/providers/profile_providers.dart';
import 'settle_up_screen.dart';

/// "Select a balance to settle" — lists every simplified-debt suggestion
/// that involves the current user in this group, matching Splitwise's own
/// settle-up entry point.
class SelectBalanceToSettleScreen extends ConsumerWidget {
  final String groupId;
  const SelectBalanceToSettleScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final suggestions = ref.watch(groupSettlementSuggestionsProvider(groupId));
    final myUserId = ref.watch(currentUserIdProvider);
    final mine = suggestions.where((s) => s.fromUserId == myUserId || s.toUserId == myUserId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Select a balance to settle')),
      body: AsyncValueWidget<List<UserBalance>>(
        value: balancesAsync,
        data: (_) {
          if (mine.isEmpty) {
            return const EmptyState(icon: Icons.check_circle_outline, title: 'You are settled up in this group');
          }
          return ListView(
            children: [
              for (final s in mine) _BalanceRow(groupId: groupId, suggestion: s, myUserId: myUserId!),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceRow extends ConsumerWidget {
  final String groupId;
  final SettlementSuggestion suggestion;
  final String myUserId;
  const _BalanceRow({required this.groupId, required this.suggestion, required this.myUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iOwe = suggestion.fromUserId == myUserId;
    final otherUserId = iOwe ? suggestion.toUserId : suggestion.fromUserId;
    final otherProfile = ref.watch(profileByIdProvider(otherUserId)).valueOrNull;

    return ListTile(
      leading: UserAvatar(pictureUrl: otherProfile?.pictureUrl, displayName: otherProfile?.fullName ?? ''),
      title: Text(otherProfile?.fullName ?? '...'),
      trailing: Text(
        '${iOwe ? 'you owe' : 'you are owed'} ${suggestion.amount.format()}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: iOwe ? BalanceColors.negative(context) : BalanceColors.positive(context),
        ),
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SettleUpScreen(
          groupId: groupId,
          fromUserId: suggestion.fromUserId,
          fromDisplayName: iOwe ? 'You' : (otherProfile?.fullName ?? '...'),
          toUserId: suggestion.toUserId,
          toDisplayName: iOwe ? (otherProfile?.fullName ?? '...') : 'You',
          currencyCode: suggestion.amount.currencyCode,
          suggestedCents: suggestion.amount.cents,
        ),
      )),
    );
  }
}
