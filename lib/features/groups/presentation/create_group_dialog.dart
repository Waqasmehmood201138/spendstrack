import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_type.dart';
import '../providers/groups_providers.dart';

/// Shows the create-group dialog and returns the new group's id, or null if
/// cancelled. A dialog rather than a route — this is a single-field form,
/// consistent with [architecture.md]'s "short forms are dialogs" convention.
Future<String?> showCreateGroupDialog(BuildContext context) {
  return showDialog<String>(context: context, builder: (_) => const CreateGroupDialog());
}

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
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
        _errorMessage = 'Could not create group. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Group name', errorText: _errorMessage),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: GroupType.values.map((type) {
              return ChoiceChip(
                label: Text(type.label),
                avatar: Icon(type.icon, size: 18),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}
