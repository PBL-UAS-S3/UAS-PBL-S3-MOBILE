import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFF2842F);
  static const primaryDark = Color(0xFFDD6F1B);
  static const primaryDarkText = Color(0xFFB9540A);
  static const primarySoft = Color(0xFFFEF1E6);
  static const bg = Color(0xFFFBF8F5);
  static const surface = Colors.white;
  static const border = Color(0xFFE7E2DA);
  static const textDark = Color(0xFF1E293B);
  static const textGrey = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  );
}