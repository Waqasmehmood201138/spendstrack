import 'package:flutter/material.dart';

/// App-wide Material 3 theme. Green seed color echoes the "money" domain
/// without literally copying Splitwise's brand palette.
class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF1B8E5A);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}

/// Positive balance ("you are owed") vs negative balance ("you owe") color,
/// used consistently across balance chips/rows/detail screens.
class BalanceColors {
  const BalanceColors._();

  static Color positive(BuildContext context) => const Color(0xFF1B8E5A);
  static Color negative(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color neutral(BuildContext context) => Theme.of(context).colorScheme.outline;
}
