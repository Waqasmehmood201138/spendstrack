import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_user_model.dart';
import '../providers/expenses_providers.dart';

/// Records a payment. Per docs/database-schema.md, a payment is just an
/// expense with `is_payment = true` and two participants: the payer's
/// `paid_share` equals the amount, the payee's `owed_share` equals the
/// amount — so it nets out the debt it settles using the exact same balance
/// math as any other expense, with no special-case code path.
class SettleUpScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final String toDisplayName;
  final String currencyCode;
  final int suggestedCents;

  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.toDisplayName,
    required this.currencyCode,
    required this.suggestedCents,
  });

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  late final TextEditingController _amountController;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.suggestedCents > 0 ? (widget.suggestedCents / 100).toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Enter an amount greater than zero.');
      return;
    }
    final cents = (amount * 100).round();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(expensesRepositoryProvider).createExpense(
            groupId: widget.groupId,
            description: '${widget.fromDisplayName} paid ${widget.toDisplayName}',
            totalCents: cents,
            currencyCode: widget.currencyCode,
            categoryId: null,
            splitType: 'exact',
            isPayment: true,
            expenseDate: _date,
            users: [
              ExpenseUser(userId: widget.fromUserId, paidCents: cents, owedCents: 0),
              ExpenseUser(userId: widget.toUserId, paidCents: 0, owedCents: cents),
            ],
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Could not record this payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '${widget.fromDisplayName} pays ${widget.toDisplayName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Amount', prefixText: '${widget.currencyCode} '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Record payment'),
          ),
        ],
      ),
    );
  }
}
