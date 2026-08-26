import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/user_avatar.dart';
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
        content: const Text('This removes it from everyone\'s balance.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: AsyncValueWidget<Expense>(
        value: expenseAsync,
        data: (expense) => _ExpenseDetailBody(
          expense: expense,
          commentController: _commentController,
          isPostingComment: _isPostingComment,
          onPostComment: _postComment,
        ),
      ),
    );
  }
}

class _ExpenseDetailBody extends ConsumerWidget {
  final Expense expense;
  final TextEditingController commentController;
  final bool isPostingComment;
  final VoidCallback onPostComment;

  const _ExpenseDetailBody({
    required this.expense,
    required this.commentController,
    required this.isPostingComment,
    required this.onPostComment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(expense.categoryId));
    final commentsAsync = ref.watch(expenseCommentsProvider(expense.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(category?.icon ?? Icons.receipt_long, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.description, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${expense.expenseDate.year}-${expense.expenseDate.month.toString().padLeft(2, '0')}-${expense.expenseDate.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(expense.cost.format(), style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const Divider(height: 32),
        Text('Split', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...expense.users.map((u) => _ParticipantShareTile(userId: u.userId, paidCents: u.paidCents, owedCents: u.owedCents, currencyCode: expense.cost.currencyCode)),
        const Divider(height: 32),
        Text('Comments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AsyncValueWidget<List<ExpenseComment>>(
          value: commentsAsync,
          data: (comments) => Column(
            children: comments.map((c) => _CommentTile(comment: c)).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: const InputDecoration(hintText: 'Add a comment'),
                onSubmitted: (_) => onPostComment(),
              ),
            ),
            IconButton(
              onPressed: isPostingComment ? null : onPostComment,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParticipantShareTile extends ConsumerWidget {
  final String userId;
  final int paidCents;
  final int owedCents;
  final String currencyCode;

  const _ParticipantShareTile({
    required this.userId,
    required this.paidCents,
    required this.owedCents,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final name = profileAsync.valueOrNull?.fullName ?? '...';
    final pictureUrl = profileAsync.valueOrNull?.pictureUrl;
    final net = paidCents - owedCents;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(pictureUrl: pictureUrl, displayName: name, radius: 16),
      title: Text(name),
      subtitle: Text(paidCents > 0 ? 'Paid ${(paidCents / 100).toStringAsFixed(2)}' : 'Did not pay'),
      trailing: Text(
        net == 0 ? 'settled' : '${net > 0 ? '+' : ''}${(net / 100).toStringAsFixed(2)}',
        style: TextStyle(
          color: net > 0
              ? Colors.green
              : net < 0
                  ? Theme.of(context).colorScheme.error
                  : null,
          fontWeight: FontWeight.bold,
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
        child: Text(
          comment.content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
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
