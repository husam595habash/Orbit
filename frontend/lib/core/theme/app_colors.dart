import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const purple = Color(0xFF7C3AED);
  static const pink = Color(0xFFFF477E);
  static const orange = Color(0xFFFFB84D);
  static const backgroundDark = Color(0xFF1A1A1C);
  static const surfaceDark = Color(0xFF2A2A2E);
  static const textLight = Color(0xFFE6E6E8);

  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, pink, orange],
  );
}
