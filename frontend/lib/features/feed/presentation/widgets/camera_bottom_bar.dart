import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'capture_button.dart';
import 'gallery_thumbnail_button.dart';

/// Gallery thumbnail (left), shutter button (center), balancing space (right).
class CameraBottomBar extends StatelessWidget {
  const CameraBottomBar({
    super.key,
    required this.galleryThumbnail,
    required this.onOpenGallery,
    required this.onCapture,
    required this.isCapturing,
  });

  final Uint8List? galleryThumbnail;
  final VoidCallback onOpenGallery;
  final VoidCallback onCapture;
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GalleryThumbnailButton(
                thumbnail: galleryThumbnail,
                onTap: onOpenGallery,
              ),
            ),
          ),
          CaptureButton(onCapture: onCapture, isBusy: isCapturing),
          const Expanded(child: SizedBox(width: 44, height: 44)),
        ],
      ),
    );
  }
}
