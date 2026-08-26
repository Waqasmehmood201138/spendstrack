import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';
import '../domain/expense_participant.dart';
import '../domain/payer_selection.dart';
import 'enter_paid_amounts_screen.dart';

/// "Who paid?" — matches Splitwise's own screen: a flat list of
/// participants (tapping one immediately pops with that person as sole
/// payer) plus a "Multiple people" row that pushes [EnterPaidAmountsScreen].
class WhoPaidScreen extends StatelessWidget {
  final List<ExpenseParticipant> participants;
  final int totalCents;
  final String currencyCode;

  const WhoPaidScreen({
    super.key,
    required this.participants,
    required this.totalCents,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who paid?')),
      body: ListView(
        children: [
          for (final p in participants)
            ListTile(
              leading: UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 18),
              title: Text(p.displayName),
              onTap: () => Navigator.of(context).pop(PayerSelection({p.userId: totalCents})),
            ),
          const Divider(height: 32),
          ListTile(
            title: const Text('Multiple people'),
            onTap: () async {
              final result = await Navigator.of(context).push<PayerSelection>(
                MaterialPageRoute(
                  builder: (_) => EnterPaidAmountsScreen(
                    participants: participants,
                    totalCents: totalCents,
                    currencyCode: currencyCode,
                  ),
                ),
              );
              if (result != null && context.mounted) Navigator.of(context).pop(result);
            },
          ),
        ],
      ),
    );
  }
}
