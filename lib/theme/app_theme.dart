import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF0A7A47);
  static const lime = Color(0xFFB7FF3C);
  static const bg = Color(0xFFF2F6F4);
  static const card = Colors.white;
  static const text = Color(0xFF0B1F17);
  static const muted = Color(0xFF5D6E67);
  static const dark = Color(0xFF063725);
  static const stroke = Color(0xFFE2ECE7);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        secondary: AppColors.lime,
        surface: AppColors.card,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
            displayMedium: base.textTheme.displayMedium?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
            headlineLarge: base.textTheme.headlineLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w800,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Tajawal',
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Tajawal',
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.stroke),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        indicatorColor: AppColors.green.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.stroke),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: AppColors.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green, width: 1.6),
        ),
      ),
    );
  }
}
