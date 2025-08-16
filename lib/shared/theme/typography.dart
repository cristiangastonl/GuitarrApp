import 'package:flutter/material.dart';
import 'colors.dart';

/// GuitarrApp Typography System
/// Optimized for music apps with clear hierarchy and excellent readability
class GuitarrTypography {
  GuitarrTypography._();

  // === FONT FAMILIES ===
  // Using system fonts optimized for each platform
  static const String _primaryFontFamily = 'SF Pro Display'; // iOS style
  static const String _secondaryFontFamily = 'Roboto'; // Android/Web fallback
  static const String _monospaceFontFamily = 'SF Mono'; // Code/tablature

  // === FONT WEIGHTS ===
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // === DISPLAY STYLES ===
  // Large headings for main screens and important information
  
  /// Display Large - Main app title, welcome screens
  static TextStyle get displayLarge => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 32,
    fontWeight: extraBold,
    height: 1.2,
    letterSpacing: -0.5,
    color: GuitarrColors.textPrimary,
  );

  /// Display Medium - Section headers, screen titles
  static TextStyle get displayMedium => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 28,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: -0.25,
    color: GuitarrColors.textPrimary,
  );

  /// Display Small - Card titles, feature headers
  static TextStyle get displaySmall => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
    color: GuitarrColors.textPrimary,
  );

  // === HEADLINE STYLES ===
  // Medium-large text for important content
  
  /// Headline Large - BPM display, main metrics
  static TextStyle get headlineLarge => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 48,
    fontWeight: extraBold,
    height: 1.1,
    letterSpacing: -1,
    color: GuitarrColors.ampOrange,
  );

  /// Headline Medium - Song titles, riff names
  static TextStyle get headlineMedium => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0.15,
    color: GuitarrColors.textPrimary,
  );

  /// Headline Small - Artist names, secondary info
  static TextStyle get headlineSmall => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 18,
    fontWeight: medium,
    height: 1.35,
    letterSpacing: 0.15,
    color: GuitarrColors.textSecondary,
  );

  // === TITLE STYLES ===
  // Titles and labels for UI elements
  
  /// Title Large - Modal titles, dialog headers
  static TextStyle get titleLarge => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 22,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
    color: GuitarrColors.textPrimary,
  );

  /// Title Medium - Button text, tab labels
  static TextStyle get titleMedium => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    color: GuitarrColors.textPrimary,
  );

  /// Title Small - Small button text, chip labels
  static TextStyle get titleSmall => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    color: GuitarrColors.textPrimary,
  );

  // === BODY STYLES ===
  // Regular text content
  
  /// Body Large - Main content, descriptions
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _secondaryFontFamily,
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
    color: GuitarrColors.textSecondary,
  );

  /// Body Medium - Secondary content, captions
  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _secondaryFontFamily,
    fontSize: 14,
    fontWeight: regular,
    height: 1.45,
    letterSpacing: 0.25,
    color: GuitarrColors.textSecondary,
  );

  /// Body Small - Helper text, hints
  static TextStyle get bodySmall => TextStyle(
    fontFamily: _secondaryFontFamily,
    fontSize: 12,
    fontWeight: regular,
    height: 1.4,
    letterSpacing: 0.4,
    color: GuitarrColors.textTertiary,
  );

  // === LABEL STYLES ===
  // Labels and small text elements
  
  /// Label Large - Form labels, section labels
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    color: GuitarrColors.textPrimary,
  );

  /// Label Medium - Input labels, metadata
  static TextStyle get labelMedium => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 12,
    fontWeight: medium,
    height: 1.35,
    letterSpacing: 0.5,
    color: GuitarrColors.textTertiary,
  );

  /// Label Small - Tiny labels, badges
  static TextStyle get labelSmall => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 10,
    fontWeight: medium,
    height: 1.3,
    letterSpacing: 0.5,
    color: GuitarrColors.textTertiary,
  );

  // === SPECIAL STYLES ===
  // Music-specific text styles
  
  /// BPM Display - Large, prominent BPM numbers
  static TextStyle get bpmDisplay => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 64,
    fontWeight: extraBold,
    height: 1.0,
    letterSpacing: -2,
    color: GuitarrColors.ampOrange,
  );

  /// Tablature - Monospace for guitar tabs
  static TextStyle get tablature => TextStyle(
    fontFamily: _monospaceFontFamily,
    fontSize: 14,
    fontWeight: regular,
    height: 1.2,
    letterSpacing: 0,
    color: GuitarrColors.textPrimary,
  );

  /// Technique Tag - Small tags for guitar techniques
  static TextStyle get techniqueTag => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 11,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: 0.3,
    color: GuitarrColors.textPrimary,
  );

  /// Timer Display - Digital timer style
  static TextStyle get timerDisplay => TextStyle(
    fontFamily: _monospaceFontFamily,
    fontSize: 24,
    fontWeight: bold,
    height: 1.1,
    letterSpacing: 1,
    color: GuitarrColors.guitarTeal,
  );

  /// Success Message - Positive feedback
  static TextStyle get successMessage => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.1,
    color: GuitarrColors.success,
  );

  /// Error Message - Error feedback
  static TextStyle get errorMessage => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.25,
    color: GuitarrColors.error,
  );

  // === BUTTON STYLES ===
  // Text styles for different button types
  
  /// Primary Button - Main action buttons
  static TextStyle get buttonPrimary => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
    color: GuitarrColors.textPrimary,
  );

  /// Secondary Button - Secondary action buttons
  static TextStyle get buttonSecondary => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.3,
    letterSpacing: 0.25,
    color: GuitarrColors.ampOrange,
  );

  /// Text Button - Text-only buttons
  static TextStyle get buttonText => TextStyle(
    fontFamily: _primaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    color: GuitarrColors.guitarTeal,
  );

  // === UTILITY METHODS ===
  
  /// Creates a text style with custom color
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  /// Creates a text style with custom weight
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) {
    return baseStyle.copyWith(fontWeight: weight);
  }

  /// Creates a text style with custom size
  static TextStyle withSize(TextStyle baseStyle, double size) {
    return baseStyle.copyWith(fontSize: size);
  }

  /// Creates emphasized version of any text style
  static TextStyle emphasized(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: GuitarrColors.textPrimary,
    );
  }

  /// Creates muted version of any text style
  static TextStyle muted(TextStyle baseStyle) {
    return baseStyle.copyWith(
      color: GuitarrColors.textTertiary,
    );
  }

  /// Creates a text style for specific genres
  static TextStyle genreStyle(String genre) {
    return titleMedium.copyWith(
      color: GuitarrColors.getGenreColor(genre),
      fontWeight: semiBold,
    );
  }
}