import 'package:flutter/material.dart';

const _groupGradients = [
  [Color(0xFF7A1E3D), Color(0xFFD6336C)],
  [Color(0xFF0F5C56), Color(0xFF1CAE79)],
  [Color(0xFFB5461D), Color(0xFFF08A3C)],
  [Color(0xFF4A2A7A), Color(0xFF8B5CF6)],
  [Color(0xFF1B4B7A), Color(0xFF3B82C4)],
  [Color(0xFF7A1B1B), Color(0xFFC44545)],
  [Color(0xFF2A5F3A), Color(0xFF5AA86B)],
  [Color(0xFF6B4A1B), Color(0xFFB98A3C)],
];

/// Deterministic gradient colors for a given group id — the same pair a
/// [GroupAvatar] with this seed renders, exposed separately so the group
/// detail screen's hero header can reuse it as a full-bleed background.
List<Color> groupHeroGradient(String seed) => _groupGradients[seed.hashCode.abs() % _groupGradients.length];

/// Splitwise auto-generates a unique colorful geometric icon per group.
/// This approximates that with a deterministic gradient (picked from the
/// group id's hash, so it's stable across rebuilds) plus the group type's
/// icon on top — no image asset pipeline required.
class GroupAvatar extends StatelessWidget {
  final String seed;
  final IconData icon;
  final double size;

  const GroupAvatar({super.key, required this.seed, required this.icon, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final pair = groupHeroGradient(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: pair),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
