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
      secondary: OcpColors.ocpAccent,
      surface: OcpColors.ocpPanel,
    ),
    fontFamily: 'monospace',
    appBarTheme: const AppBarTheme(
      backgroundColor: OcpColors.ocpPanel2,
      foregroundColor: OcpColors.ocpText,
    ),
    cardTheme: CardThemeData(
      color: OcpColors.ocpPanel2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: OcpColors.ocpBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OcpColors.ocpAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 2,
        shadowColor: Colors.black45,
      ),
    ),
    textTheme: const TextTheme(),
  );
}