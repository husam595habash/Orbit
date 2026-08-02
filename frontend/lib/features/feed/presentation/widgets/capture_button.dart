import 'package:flutter/material.dart';

/// The large circular shutter button. Scales down while pressed for a
/// tactile feel, matching the capture affordance in Instagram's camera.
class CaptureButton extends StatefulWidget {
  const CaptureButton({super.key, required this.onCapture, this.isBusy = false});

  final VoidCallback onCapture;
  final bool isBusy;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isBusy ? null : (_) => _setPressed(true),
      onTapUp: widget.isBusy
          ? null
          : (_) {
              _setPressed(false);
              widget.onCapture();
            },
      onTapCancel: widget.isBusy ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 3)),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isBusy ? Colors.white38 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
