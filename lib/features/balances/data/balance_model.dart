import '../../../core/money/money.dart';

/// One row from the `group_member_balances` or `friend_balances` Postgres
/// view: how much a given user is net owed (positive) or owes (negative) in
/// one currency. A user can have multiple [UserBalance]s in the same
/// group/friendship if expenses were logged in more than one currency —
/// balances across different currencies are never summed together.
class UserBalance {
  final String userId;
  final Money amount;

  const UserBalance({required this.userId, required this.amount});

  factory UserBalance.fromGroupBalanceJson(Map<String, dynamic> json) => UserBalance(
        userId: json['user_id'] as String,
        amount: Money.fromDecimal(json['net_balance'] as num, json['currency_code'] as String),
      );

  factory UserBalance.fromFriendBalanceJson(Map<String, dynamic> json) => UserBalance(
        userId: json['friend_id'] as String,
        amount: Money.fromDecimal(json['net_balance'] as num, json['currency_code'] as String),
      );
}
