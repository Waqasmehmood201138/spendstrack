import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';

/// Light / Dark / System default — a real, functional theme switch (see
/// core/theme/theme_mode_provider.dart), unlike Email settings/Security
/// which are UI-only placeholders for now.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  secondary: const Icon(Icons.light_mode_outlined),
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: mode,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: mode,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  secondary: const Icon(Icons.contrast),
                  title: const Text('System default'),
                  subtitle: const Text('App appearance adjusts to match your system settings'),
                  value: ThemeMode.system,
                  groupValue: mode,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
