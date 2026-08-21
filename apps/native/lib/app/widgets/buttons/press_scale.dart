import 'package:flutter/material.dart';

final class PressScale extends StatefulWidget {
  const PressScale({
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 100),
    super.key,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool enabled;
  final double scale;
  final Duration duration;

  @override
  State<PressScale> createState() => _PressScaleState();
}

final class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;

  void _setPressed({required bool pressed}) {
    if (_isPressed == pressed) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _setPressed(pressed: true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(pressed: false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(pressed: false) : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
