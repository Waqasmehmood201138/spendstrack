import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
      leading: CategoryIcon(category: selected),
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

/// A category's icon on its group color — the small colored square seen
/// throughout Splitwise's category picker and expense rows. Falls back to a
/// neutral square when there's no category yet.
class CategoryIcon extends StatelessWidget {
  final Category? category;
  final double size;
  const CategoryIcon({super.key, required this.category, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colors = categoryGroupColors[category?.groupName] ?? categoryGroupColors['Uncategorized']!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(size * 0.2)),
      child: Icon(category?.icon ?? Icons.category, color: colors.foreground, size: size * 0.55),
    );
  }
}

/// The reusable list content (grouped-by-parent, expandable) behind both the
/// bottom sheet ([CategoryPicker]) and the full-screen route reached from
/// Add Expense's category icon — one implementation, two presentations.
class CategoryPickerBody extends ConsumerWidget {
  const CategoryPickerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return AsyncValueWidget<List<Category>>(
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
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: FractionallySizedBox(heightFactor: 0.75, child: CategoryPickerBody()),
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
        leading: CategoryIcon(category: parent),
        title: Text(parent.name),
        onTap: () => Navigator.of(context).pop(parent.id),
      );
    }
    return ExpansionTile(
      leading: CategoryIcon(category: parent),
      title: Text(parent.name),
      children: children
          .map((child) => ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                leading: CategoryIcon(category: child, size: 32),
                title: Text(child.name),
                onTap: () => Navigator.of(context).pop(child.id),
              ))
          .toList(),
    );
  }
}
