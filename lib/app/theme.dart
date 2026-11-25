import 'package:flutter/material.dart';

/// Paleta inspirada en los colores institucionales (azul marino, azul claro
/// y blanco). Cámbiela aquí para modificar toda la aplicación.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF0B2A5B);
  static const Color blue = Color(0xFF1565C0);
  static const Color sky = Color(0xFF4FA3E0);
  static const Color light = Color(0xFFE3F2FD);
  static const Color background = Color(0xFFF2F7FC);
  static const Color error = Color(0xFFC62828);
  static const Color ok = Color(0xFF2E7D32);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.navy,
      secondary: AppColors.sky,
      brightness: Brightness.light,
    );
    final radius = BorderRadius.circular(14);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.withAlpha(110),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.sky.withAlpha(90)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.blue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
