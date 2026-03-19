import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF00A8E8);
  static const Color primaryBlueDark = Color(0xFF0077BE);
  static const Color primaryDarkGrey = Color(0xFF2C3E50);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGold = Color(0xFFFFA500);

  // Background
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color cardBackground = Color(0x33FFFFFF);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFBBBBBB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
  );
}
