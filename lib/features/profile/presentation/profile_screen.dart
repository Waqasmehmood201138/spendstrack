import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_model.dart';
import '../providers/profile_providers.dart';
import 'account_settings_screen.dart';
import 'appearance_screen.dart';
import 'email_settings_screen.dart';
import 'security_settings_screen.dart';

/// The "Account" tab — matches Splitwise's own layout: profile summary,
/// Preferences, Feedback, then Log out and footer branding.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: AsyncValueWidget<Profile>(
        value: profileAsync,
        data: (profile) => ListView(
          children: [
            ListTile(
              leading: UserAvatar(pictureUrl: profile.pictureUrl, displayName: profile.fullName, radius: 28),
              title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(profile.email),
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AccountSettingsScreen(profile: profile)),
                ),
                child: const Text('Edit'),
              ),
            ),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Email settings'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmailSettingsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Security'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceScreen())),
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
              title: Text('Log out', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'SpendsTrack — split expenses with friends, the fair way.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
