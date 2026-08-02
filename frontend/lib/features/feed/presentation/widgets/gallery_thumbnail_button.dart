import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Small square button, bottom-left of the camera screen, previewing the
/// most recent gallery photo. Tapping it opens the OS image picker.
class GalleryThumbnailButton extends StatelessWidget {
  const GalleryThumbnailButton({super.key, required this.thumbnail, required this.onTap});

  final Uint8List? thumbnail;
  final VoidCallback onTap;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
          color: Colors.black26,
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: thumbnail != null
              ? Image.memory(
                  thumbnail!,
                  key: ValueKey(thumbnail.hashCode),
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.photo_library_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
