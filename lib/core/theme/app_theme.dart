import 'package:flutter/material.dart';

/// App-wide Material 3 theme, calibrated to match Splitwise's own palette
/// (green for "you're owed", warm orange for "you owe") rather than a
/// generic Material seed — see docs/architecture.md for why pixel-fidelity
/// to the reference app matters here.
class AppTheme {
  const AppTheme._();

  static const primaryGreen = Color(0xFF1CAE79);
  static const debtOrange = Color(0xFFE8622C);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.light).copyWith(
      primary: primaryGreen,
      error: debtOrange,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryGreen)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryGreen : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryGreen.withOpacity(0.5) : null,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.dark).copyWith(
      primary: primaryGreen,
      error: debtOrange,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryGreen)),
    );
  }
}

/// Positive balance ("you are owed") vs negative balance ("you owe") color —
/// matches Splitwise's own convention exactly (green / warm orange), used
/// consistently across balance chips, rows, and detail screens.
class BalanceColors {
  const BalanceColors._();

  static Color positive(BuildContext context) => AppTheme.primaryGreen;
  static Color negative(BuildContext context) => AppTheme.debtOrange;
  static Color neutral(BuildContext context) => Theme.of(context).colorScheme.outline;
}

/// A pastel background + matching foreground for one category group, used by
/// the category picker and category icon chips throughout the app — mirrors
/// Splitwise's own color-coded category grid (purple for Entertainment,
/// green for Food & drink, yellow for Home, etc.) rather than a flat icon.
class CategoryColor {
  final Color background;
  final Color foreground;
  const CategoryColor(this.background, this.foreground);
}

/// Keyed by category *group* name (see docs/database-schema.md's seeded
/// taxonomy) — every subcategory inherits its parent group's color.
const Map<String, CategoryColor> categoryGroupColors = {
  'Uncategorized': CategoryColor(Color(0xFFEDEDED), Color(0xFF5F5F5F)),
  'Entertainment': CategoryColor(Color(0xFFEBE0F7), Color(0xFF6E3FA8)),
  'Food and drink': CategoryColor(Color(0xFFDCF3E6), Color(0xFF1B8E5A)),
  'Home': CategoryColor(Color(0xFFFBF3D2), Color(0xFF9C7A00)),
  'Life': CategoryColor(Color(0xFFFCE1E6), Color(0xFFC13A5A)),
  'Transportation': CategoryColor(Color(0xFFDCE9FB), Color(0xFF2361B5)),
  'Utilities': CategoryColor(Color(0xFFFDE7D3), Color(0xFFB5622A)),
};
