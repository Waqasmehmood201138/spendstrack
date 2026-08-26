import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/user_avatar.dart';
import '../../categories/presentation/category_picker.dart';
import '../../groups/providers/groups_providers.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/expense_user_model.dart';
import '../data/split_type.dart';
import '../domain/split_calculator.dart';
import '../providers/expenses_providers.dart';

/// A participant of the expense being created — always either a group
/// member or (for a friend expense) the current user + one friend. Kept
/// separate from [Profile] so this screen doesn't care whether it's showing
/// group members or a friend pair.
class _Participant {
  final String userId;
  final String displayName;
  final String? pictureUrl;
  const _Participant({required this.userId, required this.displayName, required this.pictureUrl});
}

/// Add-expense form covering both group expenses (`groupId` set) and direct
/// friend expenses (`friendId` set) — exactly one of the two is provided by
/// the caller. Payer is single-select by design (see docs/features-roadmap.md
/// — the schema and split_calculator already support multi-payer; the form
/// stays single-payer for now to keep the everyday flow fast, matching
/// Splitwise's own default "who paid" UX).
class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final String? friendId;
  final String currencyCode;

  const AddExpenseScreen({super.key, this.groupId, this.friendId, required this.currencyCode})
      : assert((groupId == null) != (friendId == null), 'Provide exactly one of groupId or friendId');

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _splitControllers = {};

  DateTime _date = DateTime.now();
  int? _categoryId;
  String? _payerId;
  SplitType _splitType = SplitType.equal;
  Set<String> _selectedParticipantIds = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String userId) {
    return _splitControllers.putIfAbsent(userId, () => TextEditingController());
  }

  int get _totalCents {
    final value = double.tryParse(_amountController.text.trim()) ?? 0;
    return (value * 100).round();
  }

  Future<void> _submit(List<_Participant> participants) async {
    setState(() => _errorMessage = null);

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = 'Enter a description.');
      return;
    }
    if (_totalCents <= 0) {
      setState(() => _errorMessage = 'Enter an amount greater than zero.');
      return;
    }
    final payerId = _payerId;
    if (payerId == null) {
      setState(() => _errorMessage = 'Choose who paid.');
      return;
    }
    if (_selectedParticipantIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one person to split with.');
      return;
    }

    try {
      final splits = _resolveSplits();
      final paidShares = {for (final p in participants) p.userId: p.userId == payerId ? _totalCents : 0};
      validatePaidShares(totalCents: _totalCents, paidCentsByUser: paidShares);

      final users = splits
          .map((s) => ExpenseUser(
                userId: s.userId,
                paidCents: paidShares[s.userId] ?? 0,
                owedCents: s.owedCents,
                percentage: s.percentage,
                shares: s.shares,
              ))
          .toList();

      setState(() => _isSubmitting = true);
      await ref.read(expensesRepositoryProvider).createExpense(
            groupId: widget.groupId,
            description: description,
            totalCents: _totalCents,
            currencyCode: widget.currencyCode,
            categoryId: _categoryId,
            splitType: _splitType.toJson(),
            isPayment: false,
            expenseDate: _date,
            users: users,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on SplitValidationError catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save this expense. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<ParticipantSplit> _resolveSplits() {
    final ids = _selectedParticipantIds.toList();
    switch (_splitType) {
      case SplitType.equal:
        return calculateEqualSplit(totalCents: _totalCents, participantIds: ids);
      case SplitType.exact:
        final amounts = {
          for (final id in ids) id: ((double.tryParse(_controllerFor(id).text.trim()) ?? 0) * 100).round(),
        };
        return calculateExactSplit(totalCents: _totalCents, exactCentsByUser: amounts);
      case SplitType.percentage:
        final percentages = {
          for (final id in ids) id: double.tryParse(_controllerFor(id).text.trim()) ?? 0,
        };
        return calculatePercentageSplit(totalCents: _totalCents, percentageByUser: percentages);
      case SplitType.shares:
        final shares = {
          for (final id in ids) id: int.tryParse(_controllerFor(id).text.trim()) ?? 0,
        };
        return calculateSharesSplit(totalCents: _totalCents, sharesByUser: shares);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupId != null) {
      final membersAsync = ref.watch(groupMembersProvider(widget.groupId!));
      return membersAsync.when(
        data: (members) {
          final participants = members
              .map((m) => _Participant(userId: m.userId, displayName: m.fullName, pictureUrl: m.pictureUrl))
              .toList();
          return _buildForm(participants);
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(body: Center(child: Text('Could not load group members: $e'))),
      );
    }

    final currentProfileAsync = ref.watch(currentProfileProvider);
    final friendProfileAsync = ref.watch(profileByIdProvider(widget.friendId!));
    if (currentProfileAsync.hasValue && friendProfileAsync.hasValue) {
      final Profile me = currentProfileAsync.requireValue;
      final Profile friend = friendProfileAsync.requireValue;
      final participants = [
        _Participant(userId: me.id, displayName: 'You', pictureUrl: me.pictureUrl),
        _Participant(userId: friend.id, displayName: friend.fullName, pictureUrl: friend.pictureUrl),
      ];
      return _buildForm(participants);
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildForm(List<_Participant> participants) {
    if (_selectedParticipantIds.isEmpty) {
      _selectedParticipantIds = participants.map((p) => p.userId).toSet();
    }
    _payerId ??= participants.first.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => _submit(participants),
            child: _isSubmitting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
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
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Amount', prefixText: '${widget.currencyCode} '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          CategoryPicker(selectedCategoryId: _categoryId, onChanged: (id) => setState(() => _categoryId = id)),
          const Divider(height: 32),
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
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const Divider(height: 32),
          Text('Paid by', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...participants.map((p) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: p.userId,
                groupValue: _payerId,
                onChanged: (value) => setState(() => _payerId = value),
                secondary: UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 16),
                title: Text(p.displayName),
              )),
          const Divider(height: 32),
          Text('Split', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<SplitType>(
            segments: SplitType.values
                .map((t) => ButtonSegment(value: t, label: Text(t.label, style: const TextStyle(fontSize: 12))))
                .toList(),
            selected: {_splitType},
            onSelectionChanged: (selection) => setState(() => _splitType = selection.first),
          ),
          const SizedBox(height: 12),
          ...participants.map((p) => _buildSplitRow(p)),
          _buildSplitSummary(participants),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSplitRow(_Participant p) {
    final isSelected = _selectedParticipantIds.contains(p.userId);
    Widget trailing;
    switch (_splitType) {
      case SplitType.equal:
        trailing = Checkbox(
          value: isSelected,
          onChanged: (checked) => setState(() {
            if (checked == true) {
              _selectedParticipantIds.add(p.userId);
            } else {
              _selectedParticipantIds.remove(p.userId);
            }
          }),
        );
      case SplitType.exact:
        trailing = SizedBox(
          width: 96,
          child: TextField(
            controller: _controllerFor(p.userId),
            enabled: isSelected,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '', isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        );
      case SplitType.percentage:
        trailing = SizedBox(
          width: 80,
          child: TextField(
            controller: _controllerFor(p.userId),
            enabled: isSelected,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: '%', isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        );
      case SplitType.shares:
        trailing = SizedBox(
          width: 64,
          child: TextField(
            controller: _controllerFor(p.userId),
            enabled: isSelected,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(isDense: true),
            onChanged: (_) => setState(() {}),
          ),
        );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 16),
      title: Text(p.displayName),
      onTap: _splitType == SplitType.equal
          ? () => setState(() {
                if (isSelected) {
                  _selectedParticipantIds.remove(p.userId);
                } else {
                  _selectedParticipantIds.add(p.userId);
                }
              })
          : null,
      trailing: trailing,
    );
  }

  Widget _buildSplitSummary(List<_Participant> participants) {
    if (_splitType == SplitType.equal || _totalCents <= 0) return const SizedBox.shrink();
    String message;
    switch (_splitType) {
      case SplitType.exact:
        final entered = _selectedParticipantIds
            .map((id) => ((double.tryParse(_controllerFor(id).text.trim()) ?? 0) * 100).round())
            .fold<int>(0, (a, b) => a + b);
        final remaining = (_totalCents - entered) / 100;
        message = 'Remaining: ${widget.currencyCode} ${remaining.toStringAsFixed(2)}';
      case SplitType.percentage:
        final entered = _selectedParticipantIds
            .map((id) => double.tryParse(_controllerFor(id).text.trim()) ?? 0)
            .fold<double>(0, (a, b) => a + b);
        message = 'Remaining: ${(100 - entered).toStringAsFixed(1)}%';
      case SplitType.shares:
        final totalShares = _selectedParticipantIds
            .map((id) => int.tryParse(_controllerFor(id).text.trim()) ?? 0)
            .fold<int>(0, (a, b) => a + b);
        message = 'Total shares: $totalShares';
      case SplitType.equal:
        message = '';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
