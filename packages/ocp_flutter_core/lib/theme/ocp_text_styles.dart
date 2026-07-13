import 'package:flutter/material.dart';
import 'ocp_colors.dart';

class OcpTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: OcpColors.ocpText,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: OcpColors.ocpTextMuted,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: OcpColors.ocpText,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: OcpColors.ocpTextMuted,
  );
  static const TextStyle monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    color: OcpColors.ocpCyan,
  );
}
