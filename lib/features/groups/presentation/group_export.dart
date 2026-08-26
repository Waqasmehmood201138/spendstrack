import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../expenses/data/expense_model.dart';

/// Builds a CSV of a group's expense history and shows it in a copyable
/// dialog. No native share sheet — this project has no share_plus-style
/// dependency yet, and copy-to-clipboard covers the same "get my data out"
/// need without adding one just for this.
Future<void> showGroupExportDialog(BuildContext context, String groupName, List<Expense> expenses) async {
  final visible = expenses.where((e) => !e.isDeleted).toList()
    ..sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

  final buffer = StringBuffer('Date,Description,Category,Cost,Currency,Payment\n');
  for (final e in visible) {
    final description = e.description.replaceAll('"', '""');
    buffer.writeln(
      '${e.expenseDate.toIso8601String().split('T').first},"$description",${e.categoryId ?? ''},'
      '${e.cost.toDecimal().toStringAsFixed(2)},${e.cost.currencyCode},${e.isPayment}',
    );
  }
  final csv = buffer.toString();

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$groupName — export.csv'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
            }
          },
          child: const Text('Copy CSV'),
        ),
      ],
    ),
  );
}
