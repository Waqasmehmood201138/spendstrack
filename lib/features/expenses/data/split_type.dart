/// Mirrors the Postgres `split_type` enum.
enum SplitType {
  equal,
  exact,
  percentage,
  shares,
  adjustment;

  static SplitType fromJson(String value) =>
      SplitType.values.firstWhere((t) => t.name == value, orElse: () => SplitType.equal);

  String toJson() => name;

  /// Short tab label, matching Splitwise's own "Adjust split" tab bar.
  String get tabLabel => switch (this) {
        SplitType.equal => 'Equally',
        SplitType.exact => 'Unequally',
        SplitType.percentage => 'By percentages',
        SplitType.shares => 'By shares',
        SplitType.adjustment => 'By adjustment',
      };

  String get title => switch (this) {
        SplitType.equal => 'Split equally',
        SplitType.exact => 'Split by exact amounts',
        SplitType.percentage => 'Split by percentages',
        SplitType.shares => 'Split by shares',
        SplitType.adjustment => 'Split by adjustment',
      };

  String get description => switch (this) {
        SplitType.equal => 'Select which people owe an equal share.',
        SplitType.exact => 'Specify exactly how much each person owes.',
        SplitType.percentage => "Enter the percentage split that's fair for your situation.",
        SplitType.shares =>
          'Great for time-based splitting (2 nights → 2 shares) and splitting across families (family of 3 → 3 shares).',
        SplitType.adjustment =>
          'Enter adjustments to reflect who owes extra; the remainder is distributed equally.',
      };
}
