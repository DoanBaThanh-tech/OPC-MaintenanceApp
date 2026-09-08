// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
class AppColors {
  AppColors._();
  static const primary = Color(0xFF0068A9);
  static const primaryDark = Color(0xFF004E80);
  static const success = Color(0xFF1A8754);
  static const warning = Color(0xFFD9A400);
  static const danger = Color(0xFFDC2626);
  static const background = Color(0xFFF5F8FB);
}

class AppTheme {
  AppTheme._();
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}