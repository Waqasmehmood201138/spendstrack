import 'package:flutter/material.dart';

/// Wraps any avatar widget with a small camera badge in the bottom-right
/// corner — tapping it runs [onTap] (typically pick-and-upload) while
/// showing a spinner over the badge during [isUploading]. Shared by profile
/// pictures and group logos so both get the same affordance and behavior.
class EditableAvatar extends StatelessWidget {
  final Widget avatar;
  final double size;
  final bool isUploading;
  final VoidCallback onTap;

  const EditableAvatar({
    super.key,
    required this.avatar,
    required this.onTap,
    this.size = 80,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(width: size, height: size, child: avatar),
          Positioned(
            right: -4,
            bottom: -4,
            child: InkWell(
              onTap: isUploading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: isUploading
                    ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.camera_alt, size: size * 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
