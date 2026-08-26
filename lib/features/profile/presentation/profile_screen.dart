import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../categories/providers/categories_providers.dart';
import '../data/profile_model.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: AsyncValueWidget<Profile>(
        value: profileAsync,
        data: (profile) => _ProfileForm(profile: profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final Profile profile;
  const _ProfileForm({required this.profile});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late String _defaultCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _defaultCurrency = widget.profile.defaultCurrency;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).update(
            userId: widget.profile.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            defaultCurrency: _defaultCurrency,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currenciesAsync = ref.watch(currenciesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: UserAvatar(pictureUrl: widget.profile.pictureUrl, displayName: widget.profile.fullName, radius: 40),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: widget.profile.email,
          decoration: const InputDecoration(labelText: 'Email'),
          enabled: false,
        ),
        const SizedBox(height: 12),
        currenciesAsync.when(
          data: (currencies) => DropdownButtonFormField<String>(
            value: _defaultCurrency,
            decoration: const InputDecoration(labelText: 'Default currency'),
            items: currencies
                .map((c) => DropdownMenuItem(value: c.code, child: Text('${c.code} (${c.symbol})')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _defaultCurrency = value);
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
