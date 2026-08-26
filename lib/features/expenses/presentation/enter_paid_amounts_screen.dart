import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';
import '../domain/expense_participant.dart';
import '../domain/payer_selection.dart';

/// "Enter paid amounts" — per-participant amount fields for a multi-payer
/// expense, with a running "$X of $Y, $Z left" footer exactly like
/// Splitwise's own screen. The checkmark is disabled until the amounts
/// reconcile to the total.
class EnterPaidAmountsScreen extends StatefulWidget {
  final List<ExpenseParticipant> participants;
  final int totalCents;
  final String currencyCode;

  const EnterPaidAmountsScreen({
    super.key,
    required this.participants,
    required this.totalCents,
    required this.currencyCode,
  });

  @override
  State<EnterPaidAmountsScreen> createState() => _EnterPaidAmountsScreenState();
}

class _EnterPaidAmountsScreenState extends State<EnterPaidAmountsScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String userId) =>
      _controllers.putIfAbsent(userId, () => TextEditingController());

  int get _enteredCents => widget.participants.fold<int>(
        0,
        (sum, p) => sum + ((double.tryParse(_controllerFor(p.userId).text.trim()) ?? 0) * 100).round(),
      );

  void _submit() {
    final amounts = {
      for (final p in widget.participants)
        p.userId: ((double.tryParse(_controllerFor(p.userId).text.trim()) ?? 0) * 100).round(),
    };
    Navigator.of(context).pop(PayerSelection(amounts));
  }

  @override
  Widget build(BuildContext context) {
    final entered = _enteredCents;
    final remaining = widget.totalCents - entered;
    final isReconciled = remaining == 0 && entered > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter paid amounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: isReconciled ? _submit : null,
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final p in widget.participants)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 18),
                  const SizedBox(width: 16),
                  Expanded(child: Text(p.displayName)),
                  Text('${widget.currencyCode} ', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _controllerFor(p.userId),
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.currencyCode} ${(entered / 100).toStringAsFixed(2)} of ${widget.currencyCode} ${(widget.totalCents / 100).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.currencyCode} ${(remaining / 100).toStringAsFixed(2)} left',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
