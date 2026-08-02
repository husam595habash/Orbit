import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum CameraCaptureStatus { initializing, ready, permissionDenied, error }

/// Owns the [CameraController] lifecycle: device discovery, lens switching,
/// still capture, and pause/resume around app backgrounding.
class CameraCaptureController extends ChangeNotifier {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _isSwitching = false;

  CameraCaptureStatus status = CameraCaptureStatus.initializing;
  String? errorMessage;

  CameraController? get controller => _controller;
  bool get hasMultipleCameras => _cameras.length > 1;
  bool get isSwitching => _isSwitching;

  Future<void> initialize() async {
    status = CameraCaptureStatus.initializing;
    notifyListeners();
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      _handleCameraException(e);
      return;
    }

    if (_cameras.isEmpty) {
      status = CameraCaptureStatus.error;
      errorMessage = 'No camera found on this device.';
      notifyListeners();
      return;
    }

    final backIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _cameraIndex = backIndex >= 0 ? backIndex : 0;
    await _openCamera(_cameras[_cameraIndex]);
  }

  Future<void> _openCamera(CameraDescription description) async {
    final previous = _controller;
    final next = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await next.initialize();
    } on CameraException catch (e) {
      await next.dispose();
      _handleCameraException(e);
      return;
    }

    _controller = next;
    status = CameraCaptureStatus.ready;
    errorMessage = null;
    notifyListeners();

    // Dispose the old controller after the new one is live so the preview
    // never flashes empty during a lens switch.
    await previous?.dispose();
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _isSwitching) return;
    _isSwitching = true;
    notifyListeners();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _openCamera(_cameras[_cameraIndex]);
    _isSwitching = false;
    notifyListeners();
  }

  Future<XFile?> takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return null;
    }
    try {
      return await controller.takePicture();
    } on CameraException {
      return null;
    }
  }

  /// Releases the camera while the app is backgrounded so the hardware isn't
  /// held unnecessarily; call [initialize] again on resume.
  Future<void> pause() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  void _handleCameraException(CameraException e) {
    const deniedCodes = {'CameraAccessDenied', 'CameraAccessDeniedWithoutPrompt', 'CameraAccessRestricted'};
    status = deniedCodes.contains(e.code)
        ? CameraCaptureStatus.permissionDenied
        : CameraCaptureStatus.error;
    errorMessage = e.description ?? e.code;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
