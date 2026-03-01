import 'package:flutter/material.dart';

/// Arcade theme colors - Neon style
class ArcadeColors {
  ArcadeColors._();

  // Background
  static const Color background = Color(0xFF0D0D0D);
  static const Color backgroundLight = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);

  // Neon colors
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonRed = Color(0xFFFF0040);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonPurple = Color(0xFF9D00FF);

  // Semantic colors
  static const Color success = neonGreen;
  static const Color warning = neonYellow;
  static const Color error = neonRed;
  static const Color info = neonCyan;

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted = Color(0xFF555555);

  // Star colors
  static const Color starFilled = neonYellow;
  static const Color starEmpty = Color(0xFF333333);
}

/// Arcade theme configuration
class ArcadeTheme {
  ArcadeTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ArcadeColors.background,
      colorScheme: const ColorScheme.dark(
        surface: ArcadeColors.surface,
        primary: ArcadeColors.neonGreen,
        secondary: ArcadeColors.neonCyan,
        tertiary: ArcadeColors.neonPink,
        error: ArcadeColors.neonRed,
        onPrimary: ArcadeColors.background,
        onSecondary: ArcadeColors.background,
        onSurface: ArcadeColors.textPrimary,
        onError: ArcadeColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.neonPink,
          letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.textPrimary,
          letterSpacing: 1,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.neonCyan,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ArcadeColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ArcadeColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.textPrimary,
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ArcadeColors.neonGreen,
          foregroundColor: ArcadeColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArcadeColors.neonCyan,
          side: const BorderSide(color: ArcadeColors.neonCyan, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: ArcadeColors.backgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ArcadeColors.neonCyan, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ArcadeColors.background,
        foregroundColor: ArcadeColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ArcadeColors.neonPink,
          letterSpacing: 2,
        ),
      ),
      iconTheme: const IconThemeData(
        color: ArcadeColors.neonCyan,
        size: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ArcadeColors.neonGreen,
        linearTrackColor: ArcadeColors.backgroundLight,
      ),
    );
  }
}

/// Helper class for neon glow effects
class NeonEffects {
  NeonEffects._();

  /// Creates a neon glow box shadow
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.6 * intensity),
        blurRadius: 15 * intensity,
        spreadRadius: 2 * intensity,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.3 * intensity),
        blurRadius: 30 * intensity,
        spreadRadius: 5 * intensity,
      ),
    ];
  }

  /// Creates a subtle glow for text
  static List<Shadow> textGlow(Color color, {double intensity = 1.0}) {
    return [
      Shadow(
        color: color.withValues(alpha: 0.8 * intensity),
        blurRadius: 10 * intensity,
      ),
      Shadow(
        color: color.withValues(alpha: 0.5 * intensity),
        blurRadius: 20 * intensity,
      ),
    ];
  }

  /// Border with glow effect
  static BoxDecoration glowingBorder(
    Color color, {
    double borderWidth = 2,
    double borderRadius = 8,
    double intensity = 1.0,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color, width: borderWidth),
      boxShadow: glow(color, intensity: intensity),
    );
  }

  /// Container with neon background
  static BoxDecoration neonContainer(
    Color borderColor, {
    Color? backgroundColor,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? ArcadeColors.backgroundLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 2),
      boxShadow: glow(borderColor, intensity: 0.5),
    );
  }
}

/// Feedback colors for different accuracy levels
class FeedbackColors {
  FeedbackColors._();

  static const Color perfect = ArcadeColors.neonGreen;
  static const Color good = ArcadeColors.neonCyan;
  static const Color ok = ArcadeColors.neonYellow;
  static const Color miss = ArcadeColors.neonRed;

  static Color fromAccuracy(double accuracy) {
    if (accuracy >= 0.90) return perfect;
    if (accuracy >= 0.70) return good;
    if (accuracy >= 0.50) return ok;
    return miss;
  }

  static String labelFromAccuracy(double accuracy) {
    if (accuracy >= 0.90) return 'PERFECT!';
    if (accuracy >= 0.70) return 'GOOD';
    if (accuracy >= 0.50) return 'OK';
    return 'MISS';
  }

  static int pointsFromAccuracy(double accuracy) {
    if (accuracy >= 0.90) return 100;
    if (accuracy >= 0.70) return 50;
    if (accuracy >= 0.50) return 25;
    return 0;
  }
}
