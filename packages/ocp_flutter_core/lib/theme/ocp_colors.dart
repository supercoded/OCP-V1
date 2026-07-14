import 'package:flutter/material.dart';

/// OCP-V1 color palette — gray/black INDI/ATA operator console style.
/// Status colors (green/amber/red/cyan/blue) used ONLY for status indicators,
/// not decoration. Primary UI is gray/white.
class OcpColors {
  // Backgrounds
  static const Color ocpBg = Color(0xFF111111);
  static const Color ocpPanel = Color(0xFF1A1A1A);
  static const Color ocpPanel2 = Color(0xFF222222);
  static const Color ocpPanel3 = Color(0xFF2A2A2A);

  // Borders
  static const Color ocpBorder = Color(0xFF333333);
  static const Color ocpBorder2 = Color(0xFF444444);

  // Text
  static const Color ocpText = Color(0xFFC8C8C8);
  static const Color ocpBright = Color(0xFFE8E8E8);
  static const Color ocpDim = Color(0xFF888888);
  static const Color ocpMuted = Color(0xFF666666);

  // Accent (now neutral bright gray, not neon)
  static const Color ocpAccent = Color(0xFFC8C8C8);

  // Status colors — for indicators only
  static const Color ocpGreen = Color(0xFF4CAF50);
  static const Color ocpAmber = Color(0xFFD4A017);
  static const Color ocpRed = Color(0xFFC62828);
  static const Color ocpCyan = Color(0xFF4FC3F7);
  static const Color ocpBlue = Color(0xFF42A5F5);

  // Grid
  static const Color ocpGrid = Color(0xFF2A2A2A);

  // Legacy aliases for backward compatibility with existing widget code
  // These map old names to new palette values
  static const Color ocpTextMuted = ocpDim;
}