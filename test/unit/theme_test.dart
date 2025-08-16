import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/shared/theme/colors.dart';
import '../../lib/shared/theme/typography.dart';
import '../../lib/shared/theme/app_theme.dart';

void main() {
  group('GuitarrApp Theme Tests', () {
    
    group('GuitarrColors', () {
      test('should have consistent guitarist-themed colors', () {
        // Test primary colors exist and are valid
        expect(GuitarrColors.ampOrange, isA<Color>());
        expect(GuitarrColors.guitarTeal, isA<Color>());
        expect(GuitarrColors.steelGold, isA<Color>());
        
        // Test background colors
        expect(GuitarrColors.backgroundPrimary, isA<Color>());
        expect(GuitarrColors.surface1, isA<Color>());
        expect(GuitarrColors.surface2, isA<Color>());
        expect(GuitarrColors.surface3, isA<Color>());
        
        // Test text colors
        expect(GuitarrColors.textPrimary, isA<Color>());
        expect(GuitarrColors.textSecondary, isA<Color>());
        expect(GuitarrColors.textTertiary, isA<Color>());
      });

      test('getGenreColor should return appropriate colors for different genres', () {
        // Test known genres
        expect(GuitarrColors.getGenreColor('rock'), equals(const Color(0xFFFF6B35)));
        expect(GuitarrColors.getGenreColor('metal'), equals(const Color(0xFFE53E3E)));
        expect(GuitarrColors.getGenreColor('blues'), equals(const Color(0xFF3182CE)));
        expect(GuitarrColors.getGenreColor('jazz'), equals(const Color(0xFF805AD5)));
        
        // Test case insensitivity
        expect(GuitarrColors.getGenreColor('ROCK'), equals(GuitarrColors.getGenreColor('rock')));
        expect(GuitarrColors.getGenreColor('Metal'), equals(GuitarrColors.getGenreColor('metal')));
        
        // Test unknown genre returns default
        expect(GuitarrColors.getGenreColor('unknown'), equals(GuitarrColors.ampOrange));
      });

      test('glassmorphic colors should have appropriate opacity', () {
        expect(GuitarrColors.glassOverlay.opacity, lessThan(0.5));
        expect(GuitarrColors.glassBorder.opacity, lessThan(0.8));
        expect(GuitarrColors.glassBorderSubtle.opacity, lessThan(0.3));
      });
    });

    group('GuitarrTypography', () {
      test('should have musician-specific typography styles', () {
        // Test specialized styles exist
        expect(GuitarrTypography.bpmDisplay, isA<TextStyle>());
        expect(GuitarrTypography.timerDisplay, isA<TextStyle>());
        expect(GuitarrTypography.techniqueTag, isA<TextStyle>());
        
        // Test hierarchy
        expect(GuitarrTypography.headlineLarge.fontSize, 
               greaterThan(GuitarrTypography.headlineMedium.fontSize!));
        expect(GuitarrTypography.titleLarge.fontSize, 
               greaterThan(GuitarrTypography.titleMedium.fontSize!));
        expect(GuitarrTypography.bodyLarge.fontSize, 
               greaterThan(GuitarrTypography.bodyMedium.fontSize!));
      });

      test('BPM display should have bold weight for visibility', () {
        expect(GuitarrTypography.bpmDisplay.fontWeight, 
               equals(FontWeight.w700));
      });

      test('technique tags should be compact and readable', () {
        expect(GuitarrTypography.techniqueTag.fontSize, lessThan(14));
        expect(GuitarrTypography.techniqueTag.fontWeight, 
               greaterThanOrEqualTo(FontWeight.w500));
      });
    });

    group('AppTheme', () {
      test('dark theme should be optimized for musicians', () {
        final darkTheme = AppTheme.darkTheme;
        
        // Should be dark theme
        expect(darkTheme.brightness, equals(Brightness.dark));
        
        // Primary color should be amp orange
        expect(darkTheme.colorScheme.primary, equals(GuitarrColors.ampOrange));
        
        // Background should be dark for low-light practice
        expect(darkTheme.scaffoldBackgroundColor, equals(GuitarrColors.backgroundPrimary));
        
        // Cards should have glassmorphic styling
        expect(darkTheme.cardTheme.elevation, equals(0));
        expect(darkTheme.cardTheme.color, equals(GuitarrColors.surface2));
      });

      test('button themes should follow glassmorphic design', () {
        final darkTheme = AppTheme.darkTheme;
        
        // ElevatedButton should use amp orange
        expect(darkTheme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
               equals(GuitarrColors.ampOrange));
        
        // TextButton should use teal accent
        expect(darkTheme.textButtonTheme.style?.foregroundColor?.resolve({}),
               equals(GuitarrColors.guitarTeal));
        
        // Buttons should have rounded corners
        final buttonShape = darkTheme.elevatedButtonTheme.style?.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(buttonShape?.borderRadius, equals(BorderRadius.circular(16)));
      });

      test('slider theme should be optimized for precise BPM control', () {
        final darkTheme = AppTheme.darkTheme;
        
        expect(darkTheme.sliderTheme.activeTrackColor, equals(GuitarrColors.ampOrange));
        expect(darkTheme.sliderTheme.thumbColor, equals(GuitarrColors.ampOrange));
        expect(darkTheme.sliderTheme.trackHeight, equals(6));
      });

      test('custom theme extension should provide guitarist-specific properties', () {
        final darkTheme = AppTheme.darkTheme;
        final extension = darkTheme.extension<GuitarrThemeExtension>();
        
        expect(extension, isNotNull);
        expect(extension!.glassOverlay, equals(GuitarrColors.glassOverlay));
        expect(extension.metronomeBeat, equals(GuitarrColors.metronomeBeat));
        expect(extension.successColor, equals(GuitarrColors.success));
      });
    });

    group('Theme Integration', () {
      test('colors should work well together in dark environments', () {
        // Test contrast ratios for accessibility
        final background = GuitarrColors.backgroundPrimary;
        final primaryText = GuitarrColors.textPrimary;
        final secondaryText = GuitarrColors.textSecondary;
        
        // These should be easily readable (we'll assume good contrast)
        expect(background.computeLuminance(), lessThan(0.1)); // Dark background
        expect(primaryText.computeLuminance(), greaterThan(0.7)); // Light text
      });

      test('glassmorphic elements should have proper layering', () {
        // Glass overlay should be subtle
        expect(GuitarrColors.glassOverlay.opacity, lessThan(0.2));
        
        // Surface hierarchy should be maintained
        expect(GuitarrColors.surface1.value, lessThan(GuitarrColors.surface2.value));
        expect(GuitarrColors.surface2.value, lessThan(GuitarrColors.surface3.value));
      });
    });
  });
}