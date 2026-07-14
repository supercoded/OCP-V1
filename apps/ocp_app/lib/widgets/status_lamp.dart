import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class StatusLamp extends StatelessWidget {
  final bool connected;
  final bool connecting;

  const StatusLamp({
    super.key,
    required this.connected,
    this.connecting = false,
  });

  Color _color() {
    if (connected) return OcpColors.ocpGreen;
    if (connecting) return OcpColors.ocpAmber;
    return OcpColors.ocpRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _color(),
        shape: BoxShape.circle,
      ),
    );
  }
}