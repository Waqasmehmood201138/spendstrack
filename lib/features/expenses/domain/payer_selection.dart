/// Result of the "Who paid?" flow: one or more people, each with how much
/// they paid, always summing to the expense total. A single-payer expense
/// is just the common case where this map has one entry.
class PayerSelection {
  final Map<String, int> paidCentsByUser;
  const PayerSelection(this.paidCentsByUser);

  bool get isSinglePayer => paidCentsByUser.length == 1;
  String? get singlePayerId => isSinglePayer ? paidCentsByUser.keys.first : null;
}
