import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class AnalogButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AnalogButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<AnalogButton> createState() => _AnalogButtonState();
}

class _AnalogButtonState extends State<AnalogButton> {
  bool _pressed = false;

  void _update(bool pressed) {
    setState(() {
      _pressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = _pressed ? 2.0 : 0.0;
    return GestureDetector(
      onTapDown: (_) => _update(true),
      onTapUp: (_) {
        _update(false);
        widget.onPressed();
      },
      onTapCancel: () => _update(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, offset, 0),
        decoration: BoxDecoration(
          color: OcpColors.ocpAccent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black45,
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black),
          child: widget.child,
        ),
      ),
    );
  }
}
