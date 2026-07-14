import 'package:flutter/material.dart';
import 'ocp_colors.dart';

class OcpTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: OcpColors.ocpBg,
    canvasColor: OcpColors.ocpPanel,
    primaryColor: OcpColors.ocpAccent,
    colorScheme: const ColorScheme.dark(
      primary: OcpColors.ocpAccent,
      secondary: OcpColors.ocpDim,
      surface: OcpColors.ocpPanel,
      error: OcpColors.ocpRed,
    ),
    fontFamily: 'monospace',
    appBarTheme: const AppBarTheme(
      backgroundColor: OcpColors.ocpPanel2,
      foregroundColor: OcpColors.ocpText,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: OcpColors.ocpPanel2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: OcpColors.ocpBorder),
      ),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OcpColors.ocpPanel3,
        foregroundColor: OcpColors.ocpText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: OcpColors.ocpBorder,
      thickness: 0.5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OcpColors.ocpBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: OcpColors.ocpBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: OcpColors.ocpBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: OcpColors.ocpBorder2),
      ),
      hintStyle: const TextStyle(color: OcpColors.ocpMuted),
    ),
    textTheme: const TextTheme(),
  );
}