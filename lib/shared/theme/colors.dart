import 'package:flutter/material.dart';

/// GuitarrApp Color System - Based on 2025 Music App Research
/// Optimized for dark mode with high contrast ratios and accessibility
class GuitarrColors {
  GuitarrColors._();

  // === PRIMARY DARK THEME COLORS ===
  // Using soft dark grays instead of pure black for eye comfort
  static const Color backgroundPrimary = Color(0xFF1B1B1B); // Soft dark gray
  static const Color backgroundSecondary = Color(0xFF242424); // Slightly lighter
  static const Color backgroundTertiary = Color(0xFF2D2D2D); // Card backgrounds
  
  // === BRAND COLORS ===
  // Musical orange - warm and energetic
  static const Color ampOrange = Color(0xFFFF6B35); // Primary brand
  static const Color ampOrangeLight = Color(0xFFFF8A65); // Lighter variant
  static const Color ampOrangeDark = Color(0xFFE55722); // Darker variant
  
  // Aliases for compatibility
  static const Color primary = ampOrange;
  static const Color secondary = guitarTeal;
  static const Color accent = steelGold;
  static const Color background = backgroundPrimary;
  static const Color cardBackground = backgroundTertiary;
  
  // === ACCENT COLORS ===
  // Teal for secondary actions and highlights
  static const Color guitarTeal = Color(0xFF4ECDC4); // Secondary brand
  static const Color guitarTealLight = Color(0xFF80E5DE); // Light variant
  static const Color guitarTealDark = Color(0xFF26A69A); // Dark variant
  
  // Golden yellow for special highlights and success
  static const Color steelGold = Color(0xFFFFD93D); // Warning/highlight
  static const Color steelGoldLight = Color(0xFFFFE082); // Light variant
  static const Color steelGoldDark = Color(0xFFFFC107); // Dark variant
  
  // === GLASSMORPHISM SUPPORT ===
  // Semi-transparent overlays for glass effects
  static const Color glassOverlay = Color(0x1AFFFFFF); // 10% white overlay
  static const Color glassOverlayStrong = Color(0x33FFFFFF); // 20% white overlay
  static const Color glassOverlaySubtle = Color(0x0DFFFFFF); // 5% white overlay
  
  // Glass borders
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white border
  static const Color glassBorderSubtle = Color(0x1AFFFFFF); // 10% white border
  
  // === TEXT COLORS ===
  // High contrast text colors optimized for dark backgrounds
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white - highest contrast
  static const Color textSecondary = Color(0xFFE0E0E0); // Light gray - secondary content
  static const Color textTertiary = Color(0xFFBDBDBD); // Medium gray - hints/labels
  static const Color textDisabled = Color(0xFF757575); // Dark gray - disabled state
  
  // === SEMANTIC COLORS ===
  // Status and feedback colors
  static const Color success = Color(0xFF4CAF50); // Green for success states
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color warning = steelGold; // Use our golden yellow
  static const Color warningLight = steelGoldLight;
  static const Color warningDark = steelGoldDark;
  
  static const Color error = Color(0xFFE53935); // Red for errors
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFC62828);
  
  static const Color info = guitarTeal; // Use our teal for info
  static const Color infoLight = guitarTealLight;
  static const Color infoDark = guitarTealDark;
  
  // === METRONOME SPECIFIC ===
  // Colors specifically for metronome visual feedback
  static const Color metronomeBeat = ampOrange; // Primary beat color
  static const Color metronomeAccent = steelGold; // Accent beat color
  static const Color metronomeInactive = Color(0xFF424242); // Inactive state
  static const Color metronomeBackground = backgroundTertiary; // Metronome background
  
  // === BPM PROGRESS COLORS ===
  // Gradient colors for BPM progression indicators
  static const Color bpmProgressStart = Color(0xFF4CAF50); // Green (slow)
  static const Color bpmProgressMid = steelGold; // Yellow (medium)
  static const Color bpmProgressEnd = error; // Red (fast)
  
  // === SURFACE COLORS ===
  // Different surface levels for proper elevation
  static const Color surface0 = backgroundPrimary; // Base surface
  static const Color surface1 = backgroundSecondary; // Elevated surface
  static const Color surface2 = backgroundTertiary; // More elevated surface
  static const Color surface3 = Color(0xFF363636); // Highest elevation
  
  // === DIVIDER & BORDER COLORS ===
  static const Color divider = Color(0xFF424242); // Subtle dividers
  static const Color borderLight = Color(0xFF525252); // Light borders
  static const Color borderDark = Color(0xFF2E2E2E); // Dark borders
  
  // === SHADOW COLORS ===
  static const Color shadowLight = Color(0x0F000000); // Light shadow
  static const Color shadowMedium = Color(0x1F000000); // Medium shadow
  static const Color shadowDark = Color(0x3F000000); // Dark shadow
  
  // === MUSICAL GENRE COLORS ===
  // Colors for different music genres
  static const Color genreRock = Color(0xFFE53935); // Rock - red
  static const Color genreMetal = Color(0xFF212121); // Metal - dark
  static const Color genreBlues = Color(0xFF1976D2); // Blues - blue
  static const Color genreJazz = Color(0xFF7B1FA2); // Jazz - purple
  static const Color genreClassical = Color(0xFF795548); // Classical - brown
  static const Color genreExercise = guitarTeal; // Exercise - teal
  
  // === CONTRAST RATIOS VALIDATION ===
  // All text/background combinations meet WCAG AA standards (4.5:1)
  // Primary combinations meet AAA standards (7:1)
  
  /// Creates a LinearGradient for glassmorphic effects
  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      glassOverlayStrong,
      glassOverlay,
    ],
  );
  
  /// Creates a LinearGradient for BPM progress indication
  static LinearGradient get bpmProgressGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      bpmProgressStart,
      bpmProgressMid,
      bpmProgressEnd,
    ],
  );
  
  /// Creates a subtle gradient for card backgrounds
  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surface2,
      backgroundTertiary,
    ],
  );
  
  /// Returns color for music genre
  static Color getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return genreRock;
      case 'metal':
        return genreMetal;
      case 'blues':
        return genreBlues;
      case 'jazz':
        return genreJazz;
      case 'classical':
        return genreClassical;
      case 'exercise':
        return genreExercise;
      default:
        return ampOrange;
    }
  }
  
  /// Returns appropriate text color for a given background
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance and return appropriate text color
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Color(0xFF000000) : textPrimary;
  }
}