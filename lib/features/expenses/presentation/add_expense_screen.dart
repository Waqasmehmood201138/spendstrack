import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/user_avatar.dart';
import '../../balances/providers/balances_providers.dart';
import '../../categories/presentation/category_picker.dart';
import '../../categories/providers/categories_providers.dart';
import '../../friends/providers/friends_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/expense_user_model.dart';
import '../data/split_type.dart';
import '../domain/expense_participant.dart';
import '../domain/payer_selection.dart';
import '../domain/split_calculator.dart';
import '../domain/split_selection.dart';
import '../providers/expenses_providers.dart';
import 'adjust_split_screen.dart';
import 'who_paid_screen.dart';

/// Add-expense form covering three contexts, matching Splitwise's own
/// "Add expense" screen: a fixed group (`groupId` set), a fixed friend pair
/// (`friendId` set), or the general case reached from the top-level FAB
/// (neither set — participants are picked ad hoc via "With you and:").
class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final String? friendId;
  final String currencyCode;

  const AddExpenseScreen({super.key, this.groupId, this.friendId, required this.currencyCode})
      : assert(groupId == null || friendId == null, 'Provide at most one of groupId or friendId');

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  DateTime _date = DateTime.now();
  int? _categoryId;
  PayerSelection? _payerSelection;
  SplitSelection? _splitSelection;
  List<ExpenseParticipant> _manualParticipants = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  int get _totalCents => ((double.tryParse(_amountController.text.trim()) ?? 0) * 100).round();

  Future<void> _pickParticipants(List<ExpenseParticipant> currentlyExcluding) async {
    final friends = ref.read(friendsListProvider).valueOrNull ?? const [];
    final selectedIds = {for (final p in _manualParticipants) p.userId};
    final result = await showModalBottomSheet<List<ExpenseParticipant>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FriendPickerSheet(friends: friends, initiallySelected: selectedIds),
    );
    if (result != null) {
      setState(() {
        _manualParticipants = result;
        _payerSelection = null;
        _splitSelection = null;
      });
    }
  }

  Future<void> _pickPayer(List<ExpenseParticipant> participants) async {
    if (_totalCents <= 0) {
      setState(() => _errorMessage = 'Enter an amount first.');
      return;
    }
    final result = await Navigator.of(context).push<PayerSelection>(
      MaterialPageRoute(
        builder: (_) => WhoPaidScreen(participants: participants, totalCents: _totalCents, currencyCode: widget.currencyCode),
      ),
    );
    if (result != null) setState(() => _payerSelection = result);
  }

  Future<void> _pickSplit(List<ExpenseParticipant> participants) async {
    if (_totalCents <= 0) {
      setState(() => _errorMessage = 'Enter an amount first.');
      return;
    }
    final result = await Navigator.of(context).push<SplitSelection>(
      MaterialPageRoute(
        builder: (_) => AdjustSplitScreen(
          participants: participants,
          totalCents: _totalCents,
          currencyCode: widget.currencyCode,
          initialType: _splitSelection?.type ?? SplitType.equal,
        ),
      ),
    );
    if (result != null) setState(() => _splitSelection = result);
  }

  Future<void> _submit(List<ExpenseParticipant> participants) async {
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
    if (participants.isEmpty) {
      setState(() => _errorMessage = 'Add at least one other person.');
      return;
    }

    final payer = _payerSelection ?? PayerSelection({participants.first.userId: _totalCents});
    final split = _splitSelection ??
        SplitSelection(
          SplitType.equal,
          calculateEqualSplit(totalCents: _totalCents, participantIds: participants.map((p) => p.userId).toList()),
        );

    try {
      validatePaidShares(totalCents: _totalCents, paidCentsByUser: payer.paidCentsByUser);
    } on SplitValidationError catch (e) {
      setState(() => _errorMessage = e.message);
      return;
    }

    final paidByUser = payer.paidCentsByUser;
    final owedByUser = {for (final s in split.splits) s.userId: s};
    final allIds = {...paidByUser.keys, ...owedByUser.keys};
    final users = allIds
        .map((id) => ExpenseUser(
              userId: id,
              paidCents: paidByUser[id] ?? 0,
              owedCents: owedByUser[id]?.owedCents ?? 0,
              percentage: owedByUser[id]?.percentage,
              shares: owedByUser[id]?.shares,
            ))
        .toList();

    setState(() => _isSubmitting = true);
    try {
      await ref.read(expensesRepositoryProvider).createExpense(
            groupId: widget.groupId,
            description: description,
            details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
            totalCents: _totalCents,
            currencyCode: widget.currencyCode,
            categoryId: _categoryId,
            splitType: split.type.toJson(),
            isPayment: false,
            expenseDate: _date,
            users: users,
          );
      ref.invalidate(overallBalanceProvider);
      if (widget.groupId == null) ref.invalidate(nonGroupBalanceProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Could not save this expense. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupId != null) {
      final membersAsync = ref.watch(groupMembersProvider(widget.groupId!));
      return membersAsync.when(
        data: (members) => _buildForm(
          members.map((m) => ExpenseParticipant(userId: m.userId, displayName: m.fullName, pictureUrl: m.pictureUrl)).toList(),
          contextLabel: null,
        ),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(body: Center(child: Text('Could not load group members: $e'))),
      );
    }

    if (widget.friendId != null) {
      final me = ref.watch(currentProfileProvider).valueOrNull;
      final friend = ref.watch(profileByIdProvider(widget.friendId!)).valueOrNull;
      if (me == null || friend == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _buildForm(
        [
          ExpenseParticipant(userId: me.id, displayName: 'You', pictureUrl: me.pictureUrl),
          ExpenseParticipant(userId: friend.id, displayName: friend.fullName, pictureUrl: friend.pictureUrl),
        ],
        contextLabel: null,
      );
    }

    final me = ref.watch(currentProfileProvider).valueOrNull;
    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final participants = [
      ExpenseParticipant(userId: me.id, displayName: 'You', pictureUrl: me.pictureUrl),
      ..._manualParticipants,
    ];
    return _buildForm(participants, contextLabel: 'general');
  }

  Widget _buildForm(List<ExpenseParticipant> participants, {required String? contextLabel}) {
    final Profile? me = ref.watch(currentProfileProvider).valueOrNull;
    final payer = _payerSelection ?? (participants.isNotEmpty ? PayerSelection({participants.first.userId: _totalCents}) : null);
    final payerLabel = _payerLabel(payer, participants, me?.id);
    final splitLabel = _splitSelection?.type.tabLabel.toLowerCase() ?? 'equally';
    final category = ref.watch(categoryByIdProvider(_categoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isSubmitting ? null : () => _submit(participants),
          ),
        ],
      ),
      body: Column(
        children: [
          if (contextLabel == 'general')
            InkWell(
              onTap: () => _pickParticipants(participants),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: RichText(
                  // Explicit base style, not DefaultTextStyle.of(context): if
                  // that ever fails to resolve to something with a real
                  // fontSize (e.g. no ambient DefaultTextStyle in scope),
                  // Flutter silently falls back to its debug placeholder
                  // style — oversized, colored, underlined — precisely to
                  // make a missing style obvious. Better to just never risk it.
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    children: [
                      const TextSpan(text: 'With ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: 'you', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: _manualParticipants.isEmpty
                            ? ' and: Enter names or emails'
                            : ' and: ${_manualParticipants.map((p) => p.displayName).join(', ')}',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await Navigator.of(context).push<int>(
                          MaterialPageRoute(builder: (_) => const _CategoryPickerRoute()),
                        );
                        if (picked != null) setState(() => _categoryId = picked);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
                        child: Icon(category?.icon ?? Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(hintText: 'Enter a description'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Text(widget.currencyCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(hintText: '0.00'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: Theme.of(context).textTheme.headlineSmall,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text('Paid by'),
                    OutlinedButton(
                      onPressed: () => _pickPayer(participants),
                      child: Text(payerLabel),
                    ),
                    const Text('and split'),
                    OutlinedButton(
                      onPressed: () => _pickSplit(participants),
                      child: Text(splitLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined),
                    tooltip: 'Notes',
                    onPressed: () => _editNotes(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: _detailsController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Add any extra detail...'),
        ),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))],
      ),
    );
  }

  String _payerLabel(PayerSelection? payer, List<ExpenseParticipant> participants, String? myId) {
    if (payer == null) return 'you';
    if (!payer.isSinglePayer) return 'multiple people';
    final id = payer.singlePayerId;
    if (id == myId) return 'you';
    final match = participants.where((p) => p.userId == id);
    return match.isEmpty ? 'you' : match.first.displayName;
  }
}

class _FriendPickerSheet extends StatefulWidget {
  final List<Profile> friends;
  final Set<String> initiallySelected;
  const _FriendPickerSheet({required this.friends, required this.initiallySelected});

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Add someone'),
              actions: [
                TextButton(
                  onPressed: () {
                    final chosen = widget.friends
                        .where((f) => _selected.contains(f.id))
                        .map((f) => ExpenseParticipant(userId: f.id, displayName: f.fullName, pictureUrl: f.pictureUrl))
                        .toList();
                    Navigator.of(context).pop(chosen);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: widget.friends.isEmpty
                  ? const Center(child: Text('Add friends first to split with them.'))
                  : ListView(
                      children: [
                        for (final f in widget.friends)
                          CheckboxListTile(
                            secondary: UserAvatar(pictureUrl: f.pictureUrl, displayName: f.fullName, radius: 18),
                            title: Text(f.fullName),
                            value: _selected.contains(f.id),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(f.id);
                              } else {
                                _selected.remove(f.id);
                              }
                            }),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps the shared [CategoryPickerBody] as a full route so it can be
/// reached from Add Expense's category icon (matching Splitwise's
/// full-screen "Search or select a category") and pop its result back.
class _CategoryPickerRoute extends StatelessWidget {
  const _CategoryPickerRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search or select a category')),
      body: const CategoryPickerBody(),
    );
  }
}
