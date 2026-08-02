import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../camera/camera_capture_controller.dart';
import '../camera/gallery_preview_service.dart';
import '../widgets/camera_bottom_bar.dart';
import '../widgets/camera_permission_view.dart';
import '../widgets/camera_top_bar.dart';
import 'create_post_page.dart';

/// Camera-first entry point for creating a post, mirroring Instagram's
/// capture screen: live preview on open, lens switch, gallery shortcut, and
/// a shutter button that hands the captured (or picked) image to the editor.
class CameraPostPage extends StatefulWidget {
  const CameraPostPage({super.key});

  @override
  State<CameraPostPage> createState() => _CameraPostPageState();
}

class _CameraPostPageState extends State<CameraPostPage> with WidgetsBindingObserver {
  final _cameraController = CameraCaptureController();
  final _galleryService = const GalleryPreviewService();
  final _imagePicker = ImagePicker();

  Uint8List? _galleryThumbnail;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController.addListener(_onCameraStateChanged);
    _cameraController.initialize();
    _loadGalleryThumbnail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.removeListener(_onCameraStateChanged);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.initialize();
    }
  }

  void _onCameraStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadGalleryThumbnail() async {
    final thumbnail = await _galleryService.latestThumbnail();
    if (mounted) setState(() => _galleryThumbnail = thumbnail);
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _cameraController.takePicture();
      if (file != null) _openEditor(File(file.path));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _openGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) _openEditor(File(picked.path));
  }

  void _openEditor(File image) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: CreatePostPage(initialImage: image),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreview(controller: _cameraController),
          SafeArea(
            child: Column(
              children: [
                CameraTopBar(
                  onClose: () => Navigator.of(context).pop(),
                  onSwitchCamera: _cameraController.switchCamera,
                  canSwitchCamera: _cameraController.hasMultipleCameras,
                  isSwitching: _cameraController.isSwitching,
                ),
                const Spacer(),
                CameraBottomBar(
                  galleryThumbnail: _galleryThumbnail,
                  onOpenGallery: _openGallery,
                  onCapture: _capture,
                  isCapturing: _isCapturing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});

  final CameraCaptureController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.status) {
      case CameraCaptureStatus.permissionDenied:
        return CameraPermissionView(
          message: controller.errorMessage,
          onRetry: controller.initialize,
        );
      case CameraCaptureStatus.error:
        return Center(
          child: Text(
            controller.errorMessage ?? 'Unable to open the camera.',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        );
      case CameraCaptureStatus.initializing:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        );
      case CameraCaptureStatus.ready:
        final camera = controller.controller;
        if (camera == null || !camera.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: SizedBox.expand(
            key: ValueKey(camera),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: camera.value.previewSize?.height ?? 1,
                height: camera.value.previewSize?.width ?? 1,
                child: CameraPreview(camera),
              ),
            ),
          ),
        );
    }
  }
}
