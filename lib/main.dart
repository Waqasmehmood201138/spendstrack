import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env may not exist yet in a fresh checkout (see docs/setup.md) —
  // swallow the load failure so --dart-define-based config still works and
  // the app doesn't crash before it can show the "missing configuration"
  // screen below.
  try {
    await dotenv.load();
  } catch (_) {
    // No .env file — Env falls back to --dart-define.
  }

  if (!Env.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);

  runApp(const ProviderScope(child: SpendsTrackApp()));
}

/// Shown instead of crashing when Supabase credentials aren't set up yet —
/// lets UI work continue (`flutter run`) before `.env` exists.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: 48),
                SizedBox(height: 16),
                Text('Missing Supabase configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Copy .env.example to .env and fill in SUPABASE_URL and SUPABASE_ANON_KEY. See docs/setup.md.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
