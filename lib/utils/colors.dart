import 'package:flutter/material.dart';

/// App color palette matching the WakeMe design specifications.
class AppColors {
  AppColors._();

  // Core Palette
  static const Color background = Color(0xFF0B1220);
  static const Color cardBackground = Color(0xFF142235);
  static const Color secondarySurface = Color(0xFF20344A);
  static const Color primaryAccent = Color(0xFF40E0C0);
  static const Color activeTeal = Color(0xFF0C9F88);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CB1C7);
  static const Color warning = Color(0xFFFFB454);
  static const Color alarm = Color(0xFFFF756B);

  // Gradient accents
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF17283E),
      Color(0xFF111D2E),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF40E0C0),
      Color(0xFF0C9F88),
    ],
  );

  static const LinearGradient alarmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF756B),
      Color(0xFFD63B30),
    ],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFB454),
      Color(0xFFE58F1C),
    ],
  );

  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const Color borderAccent = Color(0x4D40E0C0);
}

