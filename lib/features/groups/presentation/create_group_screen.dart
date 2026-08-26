import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_type.dart';
import '../providers/groups_providers.dart';

/// Pushes the create-group screen and returns the new group's id, or null
/// if cancelled — matches Splitwise's own "Create a group" screen: an X to
/// cancel, a name field with a placeholder photo tile, and a 2x2 type grid.
Future<String?> showCreateGroupDialog(BuildContext context) {
  return Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  GroupType _type = GroupType.other;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Enter a group name');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final id = await ref.read(groupsRepositoryProvider).createGroup(name: name, type: _type);
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not create group: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Create a group'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Done'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer),
                child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_type.icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Group name'),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: [
                for (final type in [GroupType.trip, GroupType.home, GroupType.couple, GroupType.other])
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _type == type ? Theme.of(context).colorScheme.primaryContainer : null,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    onPressed: () => setState(() => _type = type),
                    icon: Icon(type.icon),
                    label: Text(type.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
