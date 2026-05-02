import 'package:flutter/material.dart';

/// Palette centralisée de l'app — single source of truth.
///
/// Esprit : santé/sport sobre & clair (option C).
/// - Le rouge corail est RÉSERVÉ aux éléments cœur/HR/Polar.
/// - Le gris foncé est utilisé pour les actions principales (boutons primaires).
/// - Le vert est uniquement pour les succès (cardio fait, objectif atteint).
/// - Pattern visuel : fond gris très clair + cards blanches avec ombre douce
///   (style iOS moderne, contraste lisible).
class AppColors {
  AppColors._();

  // === Surfaces ===
  /// Fond global de l'app — gris très clair pour faire ressortir les cards blanches.
  static const background = Color(0xFFF5F5F8);
  /// Surface principale (cards) — blanche avec ombre douce.
  static const surface = Color(0xFFFFFFFF);
  /// Surface secondaire — pour pills, badges, fonds neutres dans les cards.
  static const surfaceMuted = Color(0xFFF0F0F4);
  /// Surface plus marquée — pour boutons secondaires, séparations visuelles.
  static const surfaceVariant = Color(0xFFE6E6EC);
  static const divider = Color(0xFFE0E0E6);

  /// Ombre douce standard pour cards en relief.
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  // === Texte ===
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFFAEAEB2);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkMuted = Color(0xFF8E8E93);

  // === Accents ===
  /// Vrai rouge Polar — réservé HR/cœur/Polar/cardio (intense, presque magenta).
  static const heart = Color(0xFFE40046);
  static const heartDark = Color(0xFFB8003A);
  static const heartSoft = Color(0xFFFCE4EB);

  /// Noir Polar profond — pour zones hero, boutons primaires, valeurs fortes.
  static const polarBlack = Color(0xFF0A0A0A);
  static const polarBlackSurface = Color(0xFF161618);

  /// Action principale (boutons primaires, sélection forte) = noir Polar.
  static const action = polarBlack;

  /// Succès (objectifs atteints, validations).
  static const success = Color(0xFF34C759);
  static const successSoft = Color(0xFFE6F8EB);

  /// Information neutre (cloud, info-bulles).
  static const info = Color(0xFF007AFF);
  static const infoSoft = Color(0xFFE5F1FF);

  /// Avertissement / vigilance (rare).
  static const warning = Color(0xFFFF9500);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.heart,
      brightness: Brightness.light,
      primary: AppColors.action,
      secondary: AppColors.heart,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceMuted,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.success : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.success : AppColors.surfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.action, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textTertiary),
      ),
    );
  }
}
