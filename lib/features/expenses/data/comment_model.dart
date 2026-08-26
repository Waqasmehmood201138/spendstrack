/// Mirrors `public.comments`. `userId` is null for system-generated
/// comments (e.g. "created this expense").
class ExpenseComment {
  final String id;
  final String expenseId;
  final String? userId;
  final bool isSystem;
  final String content;
  final DateTime createdAt;

  const ExpenseComment({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.isSystem,
    required this.content,
    required this.createdAt,
  });

  factory ExpenseComment.fromJson(Map<String, dynamic> json) => ExpenseComment(
        id: json['id'] as String,
        expenseId: json['expense_id'] as String,
        userId: json['user_id'] as String?,
        isSystem: json['comment_type'] == 'system',
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
