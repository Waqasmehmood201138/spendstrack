/// A candidate participant for an expense being composed — a group member,
/// a friend, or the current user. Shared across the add-expense flow's
/// screens (main form, who-paid, enter-paid-amounts, adjust-split) so they
/// don't each need their own notion of "person in this expense".
class ExpenseParticipant {
  final String userId;
  final String displayName;
  final String? pictureUrl;

  const ExpenseParticipant({required this.userId, required this.displayName, required this.pictureUrl});
}
