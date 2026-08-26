import '../../../core/money/money.dart';
import 'expense_user_model.dart';
import 'split_type.dart';

/// Mirrors `public.expenses`. `isPayment` distinguishes a real expense from
/// a settle-up payment — see docs/database-schema.md for why there's no
/// separate settlements table.
class Expense {
  final String id;
  final String? groupId;
  final String description;
  final String? details;
  final Money cost;
  final int? categoryId;
  final SplitType splitType;
  final bool isPayment;
  final DateTime expenseDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<ExpenseUser> users;

  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.details,
    required this.cost,
    required this.categoryId,
    required this.splitType,
    required this.isPayment,
    required this.expenseDate,
    required this.createdBy,
    required this.createdAt,
    required this.deletedAt,
    required this.users,
  });

  bool get isDeleted => deletedAt != null;

  /// This expense's effect on [userId]'s balance: positive if they're owed,
  /// negative if they owe, for this single expense.
  Money netFor(String userId) {
    final match = users.where((u) => u.userId == userId);
    final cents = match.isEmpty ? 0 : match.first.netCents;
    return Money(cents, cost.currencyCode);
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final usersJson = (json['expense_users'] as List<dynamic>?) ?? const [];
    return Expense(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      description: json['description'] as String,
      details: json['details'] as String?,
      cost: Money.fromDecimal(json['cost'] as num, json['currency_code'] as String),
      categoryId: json['category_id'] as int?,
      splitType: SplitType.fromJson(json['split_type'] as String),
      isPayment: json['is_payment'] as bool? ?? false,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] == null ? null : DateTime.parse(json['deleted_at'] as String),
      users: usersJson.map((u) => ExpenseUser.fromJson(u as Map<String, dynamic>)).toList(),
    );
  }
}
