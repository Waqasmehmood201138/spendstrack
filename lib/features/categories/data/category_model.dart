import 'package:flutter/material.dart';

/// Mirrors `public.categories`. Reference data, seeded once in the migration
/// from Splitwise's own taxonomy — never created/edited by users.
class Category {
  final int id;
  final int? parentId;
  final String name;
  final String iconName;

  const Category({
    required this.id,
    required this.parentId,
    required this.name,
    required this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        parentId: json['parent_id'] as int?,
        name: json['name'] as String,
        iconName: json['icon_name'] as String,
      );

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
