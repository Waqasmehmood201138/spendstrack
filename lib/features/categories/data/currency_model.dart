/// Mirrors `public.currencies`. Reference data seeded once in the migration.
class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({required this.code, required this.name, required this.symbol});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
      );

  @override
  String toString() => '$code ($symbol)';
}
