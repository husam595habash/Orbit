import 'package:flutter/material.dart';

/// Close (X) button on the left, rotate-camera button on the right.
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.onClose,
    required this.onSwitchCamera,
    required this.canSwitchCamera,
    required this.isSwitching,
  });

  final VoidCallback onClose;
  final VoidCallback onSwitchCamera;
  final bool canSwitchCamera;
  final bool isSwitching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconButton(icon: Icons.close, onTap: onClose),
          if (canSwitchCamera)
            _CircleIconButton(
              onTap: isSwitching ? null : onSwitchCamera,
              child: AnimatedRotation(
                turns: isSwitching ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
              ),
            )
          else
            const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({this.icon, this.child, required this.onTap});

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: child ?? Icon(icon, color: Colors.white)),
        ),
      ),
    );
  }
}
