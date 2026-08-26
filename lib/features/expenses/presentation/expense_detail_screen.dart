import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../categories/data/category_model.dart';
import '../../categories/providers/categories_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/comment_model.dart';
import '../data/expense_model.dart';
import '../providers/expenses_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _commentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isPostingComment = true);
    try {
      await ref.read(expensesRepositoryProvider).addComment(expenseId: widget.expenseId, content: content);
      _commentController.clear();
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text("This removes it from everyone's balance."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expensesRepositoryProvider).deleteExpense(widget.expenseId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseAsync = ref.watch(expenseByIdProvider(widget.expenseId));
    final category = ref.watch(categoryByIdProvider(expenseAsync.valueOrNull?.categoryId));
    final colors = categoryGroupColors[category?.groupName] ?? categoryGroupColors['Uncategorized']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        actions: [IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: AsyncValueWidget<Expense>(
        value: expenseAsync,
        data: (expense) => Column(
          children: [
            Expanded(
              child: _ExpenseDetailBody(expense: expense, headerColors: colors, category: category),
            ),
            _CommentInputBar(
              controller: _commentController,
              isPosting: _isPostingComment,
              onSend: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDetailBody extends ConsumerWidget {
  final Expense expense;
  final CategoryColor headerColors;
  final Category? category;

  const _ExpenseDetailBody({required this.expense, required this.headerColors, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdByName = ref.watch(profileByIdProvider(expense.createdBy)).valueOrNull?.fullName ?? '...';
    final commentsAsync = ref.watch(expenseCommentsProvider(expense.id));
    final payers = expense.users.where((u) => u.paidCents > 0).toList();

    return ListView(
      children: [
        Container(
          width: double.infinity,
          color: headerColors.background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(category?.icon ?? Icons.receipt_long, color: headerColors.foreground),
              ),
              const SizedBox(height: 12),
              Text(expense.description, style: Theme.of(context).textTheme.headlineSmall),
              Text(expense.cost.format(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Added by $createdByName on ${_formatDate(expense.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final payer in payers) ...[
                Text(
                  '${_nameOf(ref, payer.userId)} paid ${_formatMoney(payer.paidCents, expense.cost.currencyCode)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final u in expense.users)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 2)),
                          ),
                          child: Text(
                            '${_nameOf(ref, u.userId)} owes ${_formatMoney(u.owedCents, expense.cost.currencyCode)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 32),
              Text('Comments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AsyncValueWidget<List<ExpenseComment>>(
                value: commentsAsync,
                data: (comments) => Column(children: comments.map((c) => _CommentTile(comment: c)).toList()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _nameOf(WidgetRef ref, String userId) => ref.watch(profileByIdProvider(userId)).valueOrNull?.fullName ?? '...';

  String _formatMoney(int cents, String currencyCode) => '$currencyCode ${(cents / 100).toStringAsFixed(2)}';

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onSend;
  const _CommentInputBar({required this.controller, required this.isPosting, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Add a comment', border: InputBorder.none),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(onPressed: isPosting ? null : onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final ExpenseComment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (comment.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(comment.content, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
      );
    }
    final profileAsync = ref.watch(profileByIdProvider(comment.userId!));
    final name = profileAsync.valueOrNull?.fullName ?? '...';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(pictureUrl: profileAsync.valueOrNull?.pictureUrl, displayName: name, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: '$name  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: comment.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
