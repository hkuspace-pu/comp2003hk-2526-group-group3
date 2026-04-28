import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryButtonBg = Color(0xFF2C3E50);
  static const Color primaryButtonText = Color(0xFFFF6B35);

  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(14));

  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryButtonBg,
      foregroundColor: primaryButtonText,
      disabledBackgroundColor: primaryButtonBg.withOpacity(0.7),
      disabledForegroundColor: primaryButtonText.withOpacity(0.6),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: buttonRadius,
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  );

  static final TextButtonThemeData textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryButtonText,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
