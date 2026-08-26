import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase configuration from a bundled `.env` (via flutter_dotenv) or,
/// if that key is absent, from `--dart-define` (the production-friendly path
/// that doesn't require shipping a .env asset in the app bundle).
class Env {
  const Env._();

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key';

  static String _read(String key) {
    final fromDotEnv = dotenv.maybeGet(key);
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    return String.fromEnvironment(key);
  }
}
