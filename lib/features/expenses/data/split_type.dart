/// Mirrors the Postgres `split_type` enum.
enum SplitType {
  equal,
  exact,
  percentage,
  shares;

  static SplitType fromJson(String value) =>
      SplitType.values.firstWhere((t) => t.name == value, orElse: () => SplitType.equal);

  String toJson() => name;

  String get label => switch (this) {
        SplitType.equal => 'Equally',
        SplitType.exact => 'By exact amounts',
        SplitType.percentage => 'By percentages',
        SplitType.shares => 'By shares',
      };
}
