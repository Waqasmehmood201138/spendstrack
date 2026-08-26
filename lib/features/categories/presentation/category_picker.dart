import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../data/category_model.dart';
import '../providers/categories_providers.dart';

/// A tap target that opens a bottom sheet grouped by parent category
/// (matching Splitwise's own category picker), and reports the chosen leaf
/// category id back via [onChanged].
class CategoryPicker extends ConsumerWidget {
  final int? selectedCategoryId;
  final ValueChanged<int> onChanged;

  const CategoryPicker({super.key, required this.selectedCategoryId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryByIdProvider(selectedCategoryId));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(selected?.icon ?? Icons.category),
      title: Text(selected?.name ?? 'Choose a category'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final chosen = await showModalBottomSheet<int>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _CategorySheet(),
        );
        if (chosen != null) onChanged(chosen);
      },
    );
  }
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: AsyncValueWidget<List<Category>>(
          value: categoriesAsync,
          data: (categories) {
            final parents = categories.where((c) => c.parentId == null).toList();
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: parents.length,
              itemBuilder: (context, index) {
                final parent = parents[index];
                final children = categories.where((c) => c.parentId == parent.id).toList();
                return _ParentCategoryTile(parent: parent, children: children);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ParentCategoryTile extends StatelessWidget {
  final Category parent;
  final List<Category> children;
  const _ParentCategoryTile({required this.parent, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return ListTile(
        leading: Icon(parent.icon),
        title: Text(parent.name),
        onTap: () => Navigator.of(context).pop(parent.id),
      );
    }
    return ExpansionTile(
      leading: Icon(parent.icon),
      title: Text(parent.name),
      children: children
          .map((child) => ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: Icon(child.icon),
                title: Text(child.name),
                onTap: () => Navigator.of(context).pop(child.id),
              ))
          .toList(),
    );
  }
}
