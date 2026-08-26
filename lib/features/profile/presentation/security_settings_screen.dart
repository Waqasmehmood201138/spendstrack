import 'package:flutter/material.dart';

/// Matches Splitwise's own Security screen layout. The biometric toggle is
/// a UI placeholder — wiring it to a real device passcode/biometric prompt
/// needs a native plugin (e.g. local_auth) that isn't a dependency of this
/// project yet, so it's shown disabled with an honest explanation rather
/// than faking a lock that doesn't actually lock anything.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Authenticate with biometrics'),
            subtitle: const Text('Require device passcode or biometrics to open SpendsTrack'),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biometric lock needs native device integration — not wired up yet')),
              );
            },
          ),
        ],
      ),
    );
  }
}
