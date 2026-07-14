import 'package:flutter/material.dart';
import 'ocp_colors.dart';

class OcpTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: OcpColors.ocpBright,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: OcpColors.ocpDim,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: OcpColors.ocpText,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: OcpColors.ocpDim,
  );
  static const TextStyle monospace = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    color: OcpColors.ocpDim,
  );
}