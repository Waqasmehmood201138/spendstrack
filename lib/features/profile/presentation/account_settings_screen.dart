import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../data/profile_model.dart';
import '../providers/profile_providers.dart';

/// Matches Splitwise's own "Account settings" screen: each field has its
/// own inline Edit affordance rather than one big form users have to submit
/// all at once.
class AccountSettingsScreen extends ConsumerWidget {
  final Profile profile;
  const AccountSettingsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FieldRow(
            label: 'Full name',
            value: profile.fullName,
            onEdit: () => _editName(context, ref),
          ),
          _FieldRow(
            label: 'Email address',
            value: profile.email,
            onEdit: () => _editEmail(context, ref),
          ),
          _FieldRow(
            label: 'Password',
            value: '••••••••',
            onEdit: () => _editPassword(context, ref),
          ),
          const SizedBox(height: 16),
          Text('Default currency', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          currenciesAsync.when(
            data: (currencies) => DropdownButtonFormField<String>(
              value: profile.defaultCurrency,
              items: currencies.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.code} (${c.symbol})'))).toList(),
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(profileRepositoryProvider).update(
                      userId: profile.id,
                      firstName: profile.firstName,
                      lastName: profile.lastName,
                      defaultCurrency: value,
                    );
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final firstController = TextEditingController(text: profile.firstName);
    final lastController = TextEditingController(text: profile.lastName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full name'),
        content: Row(
          children: [
            Expanded(child: TextField(controller: firstController, decoration: const InputDecoration(labelText: 'First name'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: lastController, decoration: const InputDecoration(labelText: 'Last name'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      await ref.read(profileRepositoryProvider).update(
            userId: profile.id,
            firstName: firstController.text.trim(),
            lastName: lastController.text.trim(),
            defaultCurrency: profile.defaultCurrency,
          );
    }
  }

  Future<void> _editEmail(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: profile.email);
    final newEmail = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email address'),
        content: TextField(controller: controller, keyboardType: TextInputType.emailAddress),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newEmail != null && newEmail.isNotEmpty && newEmail != profile.email) {
      try {
        await ref.read(authRepositoryProvider).updateEmail(newEmail);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Confirmation link sent to your new email address')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update email: $e')));
        }
      }
    }
  }

  Future<void> _editPassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (newPassword != null && newPassword.length >= 6) {
      try {
        await ref.read(authRepositoryProvider).updatePassword(newPassword);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update password: $e')));
        }
      }
    }
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  const _FieldRow({required this.label, required this.value, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('Edit', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
