import 'package:flutter/material.dart';

/// Mirrors `public.categories`. Reference data, seeded once in the migration
/// from Splitwise's own taxonomy — never created/edited by users.
class Category {
  final int id;
  final int? parentId;
  final String name;
  final String iconName;

  /// The top-level group this category belongs to (e.g. "Food and drink"
  /// for the "Dining out" subcategory, or its own name if it IS a top-level
  /// group) — resolved by [resolveCategoryGroups] after fetching the full
  /// list, since a single row's `parent_id` alone isn't enough to know its
  /// ultimate ancestor. Used to pick this category's color; see
  /// [CategoryIcon] and `core/theme/app_theme.dart`'s `categoryGroupColors`.
  final String groupName;

  const Category({
    required this.id,
    required this.parentId,
    required this.name,
    required this.iconName,
    this.groupName = '',
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        parentId: json['parent_id'] as int?,
        name: json['name'] as String,
        iconName: json['icon_name'] as String,
      );

  Category _withGroupName(String groupName) =>
      Category(id: id, parentId: parentId, name: name, iconName: iconName, groupName: groupName);

  /// Resolves every category's [groupName] from a freshly fetched flat list
  /// — called once by `categoriesProvider` right after loading.
  static List<Category> resolveCategoryGroups(List<Category> raw) {
    final byId = {for (final c in raw) c.id: c};
    String groupNameOf(Category c) => c.parentId == null ? c.name : (byId[c.parentId]?.name ?? c.name);
    return raw.map((c) => c._withGroupName(groupNameOf(c))).toList();
  }

  /// Maps the seeded `icon_name` string to a concrete Material icon. Falls
  /// back to a generic category glyph for any name not listed here so a new
  /// seeded row never renders a blank icon.
  IconData get icon => _iconsByName[iconName] ?? Icons.category;

  static const _iconsByName = <String, IconData>{
    'category': Icons.category,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'local_movies': Icons.local_movies,
    'music_note': Icons.music_note,
    'restaurant': Icons.restaurant,
    'restaurant_menu': Icons.restaurant_menu,
    'shopping_cart': Icons.shopping_cart,
    'liquor': Icons.liquor,
    'home': Icons.home,
    'devices': Icons.devices,
    'chair': Icons.chair,
    'cleaning_services': Icons.cleaning_services,
    'build': Icons.build,
    'account_balance': Icons.account_balance,
    'pets': Icons.pets,
    'key': Icons.key,
    'design_services': Icons.design_services,
    'favorite': Icons.favorite,
    'child_care': Icons.child_care,
    'checkroom': Icons.checkroom,
    'school': Icons.school,
    'card_giftcard': Icons.card_giftcard,
    'shield': Icons.shield,
    'local_hospital': Icons.local_hospital,
    'receipt_long': Icons.receipt_long,
    'directions_car': Icons.directions_car,
    'directions_bike': Icons.directions_bike,
    'directions_bus': Icons.directions_bus,
    'local_gas_station': Icons.local_gas_station,
    'hotel': Icons.hotel,
    'local_parking': Icons.local_parking,
    'flight': Icons.flight,
    'local_taxi': Icons.local_taxi,
    'bolt': Icons.bolt,
    'local_fire_department': Icons.local_fire_department,
    'delete': Icons.delete,
    'wifi': Icons.wifi,
    'water_drop': Icons.water_drop,
  };
}
