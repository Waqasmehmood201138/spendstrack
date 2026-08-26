import 'package:flutter/material.dart';

/// Circular avatar shared by every screen that shows a person: friends list,
/// group members, expense participants, comments. Falls back to initials
/// when [pictureUrl] is null so there's never a broken-image state.
class UserAvatar extends StatelessWidget {
  final String? pictureUrl;
  final String displayName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.pictureUrl,
    required this.displayName,
    this.radius = 20,
  });

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = pictureUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
