import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';
import '../data/split_type.dart';
import '../domain/expense_participant.dart';
import '../domain/split_calculator.dart';
import '../domain/split_selection.dart';

/// "Adjust split" — five tabs (Equally / Unequally / By percentages / By
/// shares / By adjustment) matching Splitwise's own screen exactly in
/// structure and copy. Each tab keeps its own input state for the whole
/// visit (switching tabs doesn't lose what you typed), and the checkmark
/// commits whichever tab is currently active.
class AdjustSplitScreen extends StatefulWidget {
  final List<ExpenseParticipant> participants;
  final int totalCents;
  final String currencyCode;
  final SplitType initialType;

  const AdjustSplitScreen({
    super.key,
    required this.participants,
    required this.totalCents,
    required this.currencyCode,
    this.initialType = SplitType.equal,
  });

  @override
  State<AdjustSplitScreen> createState() => _AdjustSplitScreenState();
}

class _AdjustSplitScreenState extends State<AdjustSplitScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Set<String> _equalSelected;
  final Map<String, TextEditingController> _exact = {};
  final Map<String, TextEditingController> _percentage = {};
  final Map<String, TextEditingController> _shares = {};
  final Map<String, TextEditingController> _adjustment = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _equalSelected = widget.participants.map((p) => p.userId).toSet();
    _tabController = TabController(length: SplitType.values.length, vsync: this, initialIndex: widget.initialType.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [..._exact.values, ..._percentage.values, ..._shares.values, ..._adjustment.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(Map<String, TextEditingController> store, String userId) =>
      store.putIfAbsent(userId, () => TextEditingController());

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _submit() {
    final type = SplitType.values[_tabController.index];
    try {
      List<ParticipantSplit> splits;
      switch (type) {
        case SplitType.equal:
          splits = calculateEqualSplit(totalCents: widget.totalCents, participantIds: _equalSelected.toList());
        case SplitType.exact:
          splits = calculateExactSplit(
            totalCents: widget.totalCents,
            exactCentsByUser: {
              for (final p in widget.participants) p.userId: (_num(_controller(_exact, p.userId)) * 100).round(),
            },
          );
        case SplitType.percentage:
          splits = calculatePercentageSplit(
            totalCents: widget.totalCents,
            percentageByUser: {for (final p in widget.participants) p.userId: _num(_controller(_percentage, p.userId))},
          );
        case SplitType.shares:
          splits = calculateSharesSplit(
            totalCents: widget.totalCents,
            sharesByUser: {for (final p in widget.participants) p.userId: _num(_controller(_shares, p.userId)).round()},
          );
        case SplitType.adjustment:
          splits = calculateAdjustmentSplit(
            totalCents: widget.totalCents,
            adjustmentCentsByUser: {
              for (final p in widget.participants) p.userId: (_num(_controller(_adjustment, p.userId)) * 100).round(),
            },
          );
      }
      Navigator.of(context).pop(SplitSelection(type, splits));
    } on SplitValidationError catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust split'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _submit)],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (_) => setState(() => _error = null),
          tabs: [for (final t in SplitType.values) Tab(text: t.tabLabel)],
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EqualTab(participants: widget.participants, selected: _equalSelected, totalCents: widget.totalCents,
                    currencyCode: widget.currencyCode, onChanged: (s) => setState(() => _equalSelected = s)),
                _AmountTab(type: SplitType.exact, participants: widget.participants, currencyCode: widget.currencyCode,
                    controllerFor: (id) => _controller(_exact, id), suffix: null,
                    reconciliation: _Reconciliation.amount(totalCents: widget.totalCents)),
                _AmountTab(type: SplitType.percentage, participants: widget.participants, currencyCode: widget.currencyCode,
                    controllerFor: (id) => _controller(_percentage, id), suffix: '%',
                    reconciliation: const _Reconciliation.percentage()),
                _SharesTab(participants: widget.participants, currencyCode: widget.currencyCode,
                    controllerFor: (id) => _controller(_shares, id)),
                _AmountTab(type: SplitType.adjustment, participants: widget.participants, currencyCode: widget.currencyCode,
                    controllerFor: (id) => _controller(_adjustment, id), suffix: null, prefix: '+', reconciliation: null),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Tells [_AmountTab] how to render its own reconciliation footer — either
/// against a percentage total of 100, or a dollar total in cents. Kept as
/// data (not a pre-built widget) so the tab can rebuild it on every
/// keystroke from within its own [StatefulBuilder] scope.
class _Reconciliation {
  final bool isPercentage;
  final int totalCents;
  const _Reconciliation.percentage() : isPercentage = true, totalCents = 0;
  const _Reconciliation.amount({required this.totalCents}) : isPercentage = false;
}

class _FooterText extends StatelessWidget {
  final String primary;
  final String secondary;
  const _FooterText({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(primary, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(secondary, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _TabHeader({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EqualTab extends StatelessWidget {
  final List<ExpenseParticipant> participants;
  final Set<String> selected;
  final int totalCents;
  final String currencyCode;
  final ValueChanged<Set<String>> onChanged;

  const _EqualTab({
    required this.participants,
    required this.selected,
    required this.totalCents,
    required this.currencyCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final perPerson = selected.isEmpty ? 0 : totalCents ~/ selected.length;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _TabHeader(icon: Icons.balance, title: SplitType.equal.title, description: SplitType.equal.description),
              for (final p in participants)
                CheckboxListTile(
                  secondary: UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 18),
                  title: Text(p.displayName),
                  value: selected.contains(p.userId),
                  onChanged: (checked) {
                    final next = Set<String>.from(selected);
                    if (checked == true) {
                      next.add(p.userId);
                    } else {
                      next.remove(p.userId);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ),
        _FooterText(
          primary: '$currencyCode${(perPerson / 100).toStringAsFixed(2)}/person',
          secondary: '(${selected.length} people)',
        ),
      ],
    );
  }
}

class _AmountTab extends StatelessWidget {
  final SplitType type;
  final List<ExpenseParticipant> participants;
  final String currencyCode;
  final TextEditingController Function(String userId) controllerFor;
  final String? suffix;
  final String? prefix;
  final _Reconciliation? reconciliation;

  const _AmountTab({
    required this.type,
    required this.participants,
    required this.currencyCode,
    required this.controllerFor,
    this.suffix,
    this.prefix,
    required this.reconciliation,
  });

  double _num(String userId) => double.tryParse(controllerFor(userId).text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final entered = participants.fold<double>(0, (sum, p) => sum + _num(p.userId));
        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _TabHeader(icon: Icons.tune, title: type.title, description: type.description),
                  for (final p in participants)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 18),
                          const SizedBox(width: 16),
                          Expanded(child: Text(p.displayName)),
                          if (prefix != null) Text(prefix!),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: controllerFor(p.userId),
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(isDense: true, suffixText: suffix),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (reconciliation != null)
              reconciliation!.isPercentage
                  ? _FooterText(
                      primary: '${entered.toStringAsFixed(0)}% of 100%',
                      secondary: '${(100 - entered).toStringAsFixed(0)}% left',
                    )
                  : _FooterText(
                      primary:
                          '$currencyCode${entered.toStringAsFixed(2)} of $currencyCode${(reconciliation!.totalCents / 100).toStringAsFixed(2)}',
                      secondary:
                          '$currencyCode${((reconciliation!.totalCents / 100) - entered).toStringAsFixed(2)} left',
                    ),
          ],
        );
      },
    );
  }
}

class _SharesTab extends StatelessWidget {
  final List<ExpenseParticipant> participants;
  final String currencyCode;
  final TextEditingController Function(String userId) controllerFor;

  const _SharesTab({required this.participants, required this.currencyCode, required this.controllerFor});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final total = participants.fold<int>(0, (sum, p) => sum + (int.tryParse(controllerFor(p.userId).text.trim()) ?? 0));
        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _TabHeader(icon: Icons.groups, title: SplitType.shares.title, description: SplitType.shares.description),
                  for (final p in participants)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          UserAvatar(pictureUrl: p.pictureUrl, displayName: p.displayName, radius: 18),
                          const SizedBox(width: 16),
                          Expanded(child: Text(p.displayName)),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: controllerFor(p.userId),
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('shares'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '$total total shares',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
