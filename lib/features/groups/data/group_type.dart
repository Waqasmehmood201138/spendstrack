import 'package:flutter/material.dart';

/// Mirrors the Postgres `group_type` enum, which mirrors Splitwise's own
/// `group_type` values exactly (see docs/database-schema.md).
enum GroupType {
  home,
  trip,
  couple,
  apartment,
  house,
  other;

  static GroupType fromJson(String value) =>
      GroupType.values.firstWhere((t) => t.name == value, orElse: () => GroupType.other);

  String toJson() => name;

  String get label => switch (this) {
        GroupType.home => 'Home',
        GroupType.trip => 'Trip',
        GroupType.couple => 'Couple',
        GroupType.apartment => 'Apartment',
        GroupType.house => 'House',
        GroupType.other => 'Other',
      };

  IconData get icon => switch (this) {
        GroupType.home => Icons.home,
        GroupType.trip => Icons.flight_takeoff,
        GroupType.couple => Icons.favorite,
        GroupType.apartment => Icons.apartment,
        GroupType.house => Icons.house,
        GroupType.other => Icons.group,
      };
}
