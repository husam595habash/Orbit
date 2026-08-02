import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

/// Reads gallery metadata needed for the create-post camera screen: just
/// enough to render a "most recent photo" thumbnail. Actual image selection
/// goes through the OS picker (see [ImagePicker]), which needs no separate
/// permission on modern Android/iOS.
class GalleryPreviewService {
  const GalleryPreviewService();

  Future<Uint8List?> latestThumbnail({int size = 200}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return null;

    final recent = await albums.first.getAssetListRange(start: 0, end: 1);
    if (recent.isEmpty) return null;

    return recent.first.thumbnailDataWithSize(
      ThumbnailSize.square(size),
    );
  }
}
