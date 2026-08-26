import 'package:flutter/material.dart';

/// Matches Splitwise's own Email settings layout. UI-only: there's no email
/// delivery system wired up in this project (see docs/features-roadmap.md),
/// so these checkboxes don't yet gate any actual email being sent — shown
/// as local state rather than silently pretending to save server-side.
class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final Map<String, bool> _values = {
    'When someone adds me to a group': false,
    'When someone adds me as a friend': true,
    'When an expense is added': false,
    'When an expense is edited/deleted': false,
    'When someone comments on an expense': false,
    'When an expense is due': true,
    'When someone pays me': true,
    'Monthly summary of my activity': true,
    'Major SpendsTrack news and updates': true,
  };

  static const _sections = {
    'GROUPS AND FRIENDS': ['When someone adds me to a group', 'When someone adds me as a friend'],
    'EXPENSES': [
      'When an expense is added',
      'When an expense is edited/deleted',
      'When someone comments on an expense',
      'When an expense is due',
      'When someone pays me',
    ],
    'NEWS AND UPDATES': ['Monthly summary of my activity', 'Major SpendsTrack news and updates'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final section in _sections.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                section.key,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final label in section.value)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(label),
                value: _values[label],
                onChanged: (v) => setState(() => _values[label] = v ?? false),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
