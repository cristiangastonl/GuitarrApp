import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

/// GuitarrApp Theme System
/// Modern dark-optimized theme with glassmorphism support
class AppTheme {
  AppTheme._();

  /// Main dark theme - optimized for musicians and low-light practice
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // === COLOR SCHEME ===
      colorScheme: ColorScheme.dark(
        // Primary colors
        primary: GuitarrColors.ampOrange,
        onPrimary: GuitarrColors.textPrimary,
        primaryContainer: GuitarrColors.ampOrangeDark,
        onPrimaryContainer: GuitarrColors.textPrimary,
        
        // Secondary colors
        secondary: GuitarrColors.guitarTeal,
        onSecondary: GuitarrColors.textPrimary,
        secondaryContainer: GuitarrColors.guitarTealDark,
        onSecondaryContainer: GuitarrColors.textPrimary,
        
        // Tertiary colors
        tertiary: GuitarrColors.steelGold,
        onTertiary: GuitarrColors.backgroundPrimary,
        tertiaryContainer: GuitarrColors.steelGoldDark,
        onTertiaryContainer: GuitarrColors.textPrimary,
        
        // Surface colors
        surface: GuitarrColors.backgroundPrimary,
        onSurface: GuitarrColors.textPrimary,
        surfaceContainerLowest: GuitarrColors.surface0,
        surfaceContainerLow: GuitarrColors.surface1,
        surfaceContainer: GuitarrColors.surface2,
        surfaceContainerHigh: GuitarrColors.surface3,
        
        // Background colors
        background: GuitarrColors.backgroundPrimary,
        onBackground: GuitarrColors.textPrimary,
        
        // Semantic colors
        error: GuitarrColors.error,
        onError: GuitarrColors.textPrimary,
        errorContainer: GuitarrColors.errorDark,
        onErrorContainer: GuitarrColors.textPrimary,
        
        // Outline colors
        outline: GuitarrColors.divider,
        outlineVariant: GuitarrColors.borderLight,
      ),
      
      // === SCAFFOLD ===
      scaffoldBackgroundColor: GuitarrColors.backgroundPrimary,
      
      // === APP BAR THEME ===
      appBarTheme: AppBarTheme(
        backgroundColor: GuitarrColors.backgroundPrimary,
        foregroundColor: GuitarrColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GuitarrTypography.titleLarge,
        toolbarHeight: 64,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      // === CARD THEME ===
      cardTheme: CardThemeData(
        elevation: 0,
        color: GuitarrColors.surface2,
        shadowColor: GuitarrColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: GuitarrColors.glassBorderSubtle,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // === BUTTON THEMES ===
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GuitarrColors.ampOrange,
          foregroundColor: GuitarrColors.textPrimary,
          disabledBackgroundColor: GuitarrColors.textDisabled,
          disabledForegroundColor: GuitarrColors.textTertiary,
          elevation: 0,
          shadowColor: GuitarrColors.shadowMedium,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(88, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GuitarrTypography.buttonPrimary,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GuitarrColors.guitarTeal,
          disabledForegroundColor: GuitarrColors.textDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GuitarrTypography.buttonText,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GuitarrColors.ampOrange,
          disabledForegroundColor: GuitarrColors.textDisabled,
          side: BorderSide(color: GuitarrColors.ampOrange, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GuitarrTypography.buttonSecondary,
        ),
      ),
      
      // === FLOATING ACTION BUTTON ===
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: GuitarrColors.ampOrange,
        foregroundColor: GuitarrColors.textPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // === BOTTOM NAVIGATION BAR ===
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: GuitarrColors.surface1,
        selectedItemColor: GuitarrColors.ampOrange,
        unselectedItemColor: GuitarrColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GuitarrTypography.labelMedium,
        unselectedLabelStyle: GuitarrTypography.labelSmall,
      ),
      
      // === SLIDER THEME ===
      sliderTheme: SliderThemeData(
        activeTrackColor: GuitarrColors.ampOrange,
        inactiveTrackColor: GuitarrColors.metronomeInactive,
        thumbColor: GuitarrColors.ampOrange,
        overlayColor: GuitarrColors.ampOrange.withOpacity(0.2),
        valueIndicatorColor: GuitarrColors.ampOrange,
        valueIndicatorTextStyle: GuitarrTypography.labelMedium,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      
      // === PROGRESS INDICATOR ===
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: GuitarrColors.ampOrange,
        linearTrackColor: GuitarrColors.metronomeInactive,
        circularTrackColor: GuitarrColors.metronomeInactive,
      ),
      
      // === INPUT DECORATION THEME ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GuitarrColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GuitarrColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GuitarrColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GuitarrColors.ampOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: GuitarrColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GuitarrTypography.labelLarge,
        hintStyle: GuitarrTypography.bodyMedium.copyWith(
          color: GuitarrColors.textTertiary,
        ),
      ),
      
      // === DIVIDER THEME ===
      dividerTheme: DividerThemeData(
        color: GuitarrColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // === CHIP THEME ===
      chipTheme: ChipThemeData(
        backgroundColor: GuitarrColors.surface2,
        selectedColor: GuitarrColors.ampOrange,
        disabledColor: GuitarrColors.textDisabled,
        deleteIconColor: GuitarrColors.textSecondary,
        labelStyle: GuitarrTypography.techniqueTag,
        secondaryLabelStyle: GuitarrTypography.techniqueTag,
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // === TYPOGRAPHY THEME ===
      textTheme: TextTheme(
        displayLarge: GuitarrTypography.displayLarge,
        displayMedium: GuitarrTypography.displayMedium,
        displaySmall: GuitarrTypography.displaySmall,
        headlineLarge: GuitarrTypography.headlineLarge,
        headlineMedium: GuitarrTypography.headlineMedium,
        headlineSmall: GuitarrTypography.headlineSmall,
        titleLarge: GuitarrTypography.titleLarge,
        titleMedium: GuitarrTypography.titleMedium,
        titleSmall: GuitarrTypography.titleSmall,
        bodyLarge: GuitarrTypography.bodyLarge,
        bodyMedium: GuitarrTypography.bodyMedium,
        bodySmall: GuitarrTypography.bodySmall,
        labelLarge: GuitarrTypography.labelLarge,
        labelMedium: GuitarrTypography.labelMedium,
        labelSmall: GuitarrTypography.labelSmall,
      ),
      
      // === EXTENSIONS ===
      extensions: <ThemeExtension<dynamic>>[
        GuitarrThemeExtension(
          glassOverlay: GuitarrColors.glassOverlay,
          glassBorder: GuitarrColors.glassBorder,
          metronomeBeat: GuitarrColors.metronomeBeat,
          metronomeAccent: GuitarrColors.metronomeAccent,
          bpmGradient: GuitarrColors.bpmProgressGradient,
          successColor: GuitarrColors.success,
          warningColor: GuitarrColors.warning,
          timerStyle: GuitarrTypography.timerDisplay,
          bpmStyle: GuitarrTypography.bpmDisplay,
        ),
      ],
    );
  }
  
  /// Light theme (fallback) - still optimized but not primary focus
  static ThemeData get lightTheme {
    // Create a simplified light theme based on the dark theme
    // Most users will use dark mode for music practice
    return darkTheme.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: GuitarrColors.ampOrange,
        secondary: GuitarrColors.guitarTeal,
        surface: Colors.white,
        background: Colors.grey[50]!,
        error: GuitarrColors.error,
      ),
    );
  }
  
  // Legacy getters for backward compatibility
  static ThemeData get dark => darkTheme;
  static ThemeData get light => lightTheme;
}

/// Custom theme extension for GuitarrApp specific styles
@immutable
class GuitarrThemeExtension extends ThemeExtension<GuitarrThemeExtension> {
  const GuitarrThemeExtension({
    required this.glassOverlay,
    required this.glassBorder,
    required this.metronomeBeat,
    required this.metronomeAccent,
    required this.bpmGradient,
    required this.successColor,
    required this.warningColor,
    required this.timerStyle,
    required this.bpmStyle,
  });

  final Color glassOverlay;
  final Color glassBorder;
  final Color metronomeBeat;
  final Color metronomeAccent;
  final LinearGradient bpmGradient;
  final Color successColor;
  final Color warningColor;
  final TextStyle timerStyle;
  final TextStyle bpmStyle;

  @override
  GuitarrThemeExtension copyWith({
    Color? glassOverlay,
    Color? glassBorder,
    Color? metronomeBeat,
    Color? metronomeAccent,
    LinearGradient? bpmGradient,
    Color? successColor,
    Color? warningColor,
    TextStyle? timerStyle,
    TextStyle? bpmStyle,
  }) {
    return GuitarrThemeExtension(
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassBorder: glassBorder ?? this.glassBorder,
      metronomeBeat: metronomeBeat ?? this.metronomeBeat,
      metronomeAccent: metronomeAccent ?? this.metronomeAccent,
      bpmGradient: bpmGradient ?? this.bpmGradient,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      timerStyle: timerStyle ?? this.timerStyle,
      bpmStyle: bpmStyle ?? this.bpmStyle,
    );
  }

  @override
  GuitarrThemeExtension lerp(ThemeExtension<GuitarrThemeExtension>? other, double t) {
    if (other is! GuitarrThemeExtension) {
      return this;
    }
    return GuitarrThemeExtension(
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      metronomeBeat: Color.lerp(metronomeBeat, other.metronomeBeat, t)!,
      metronomeAccent: Color.lerp(metronomeAccent, other.metronomeAccent, t)!,
      bpmGradient: LinearGradient.lerp(bpmGradient, other.bpmGradient, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      timerStyle: TextStyle.lerp(timerStyle, other.timerStyle, t)!,
      bpmStyle: TextStyle.lerp(bpmStyle, other.bpmStyle, t)!,
    );
  }
}

/// Extension to easily access custom theme properties
extension GuitarrThemeData on ThemeData {
  GuitarrThemeExtension get guitarrTheme => 
      extension<GuitarrThemeExtension>()!;
}