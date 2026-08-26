import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/user_avatar.dart';
import '../../balances/providers/balances_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/expense_user_model.dart';
import '../providers/expenses_providers.dart';

/// "Record a payment" — matches Splitwise's own screen: two avatars joined
/// by an arrow, a large editable amount, an explanatory note that no money
/// actually moves, and a single pill button. Per docs/database-schema.md, a
/// payment is just an expense with `is_payment = true` and two participants
/// whose paid/owed shares net out the debt it settles — no special-case
/// balance math needed.
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
      ref.invalidate(overallBalanceProvider);
      if (widget.groupId == null) ref.invalidate(nonGroupBalanceProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Could not record this payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _editAmount() async {
    final controller = TextEditingController(text: _amountController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(prefixText: '${widget.currencyCode} '),
        ),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Done'))],
      ),
    );
    if (result != null) setState(() => _amountController.text = result);
  }

  @override
  Widget build(BuildContext context) {
    final fromProfile = ref.watch(profileByIdProvider(widget.fromUserId)).valueOrNull;
    final toProfile = ref.watch(profileByIdProvider(widget.toUserId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Record a payment')),
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
              child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(pictureUrl: fromProfile?.pictureUrl, displayName: widget.fromDisplayName, radius: 36),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Icon(Icons.arrow_forward, size: 28)),
              UserAvatar(pictureUrl: toProfile?.pictureUrl, displayName: widget.toDisplayName, radius: 36),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.fromDisplayName} paid ${widget.toDisplayName}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _editAmount,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.currencyCode, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                Text(
                  _amountController.text.isEmpty ? '0.00' : _amountController.text,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('You are recording a payment that happened outside SpendsTrack. No money will be moved.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Record a payment'),
          ),
        ],
      ),
    );
  }
}
