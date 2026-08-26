import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_model.dart';
import '../providers/groups_providers.dart';

/// Free-text notes visible to every group member — e.g. a landlord's
/// address or emergency contact info. Matches Splitwise's own Whiteboard
/// exactly, including the helper copy.
class GroupWhiteboardScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupWhiteboardScreen({super.key, required this.group});

  @override
  ConsumerState<GroupWhiteboardScreen> createState() => _GroupWhiteboardScreenState();
}

class _GroupWhiteboardScreenState extends ConsumerState<GroupWhiteboardScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.group.whiteboard);
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(groupsRepositoryProvider).updateWhiteboard(groupId: widget.group.id, whiteboard: _controller.text);
      ref.invalidate(groupByIdProvider(widget.group.id));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whiteboard'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the whiteboard to remember important info, like your landlord\'s address or emergency contact '
              'info. The whiteboard is visible to anyone who joins your group.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
