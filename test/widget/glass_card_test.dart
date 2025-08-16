import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/shared/widgets/glass_card.dart';
import '../../lib/shared/theme/app_theme.dart';

void main() {
  group('GlassCard Widget Tests', () {
    testWidgets('GlassCard should render with glassmorphic styling', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: GlassCard(
              child: testChild,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
      
      // Verify glassmorphic styling is applied
      final glasscardWidget = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(glasscardWidget.borderRadius, equals(20));
      expect(glasscardWidget.blurStrength, equals(15));
    });

    testWidgets('MusicGlassCard should adapt colors based on genre', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Music Content');
      const genre = 'rock';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: MusicGlassCard(
              genre: genre,
              child: testChild,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Music Content'), findsOneWidget);
      expect(find.byType(MusicGlassCard), findsOneWidget);
      
      final musicGlassCard = tester.widget<MusicGlassCard>(find.byType(MusicGlassCard));
      expect(musicGlassCard.genre, equals(genre));
    });

    testWidgets('RiffGlassCard should display riff information with glassmorphic styling', (WidgetTester tester) async {
      // Arrange
      const riffName = 'Test Riff';
      const artist = 'Test Artist';
      const genre = 'metal';
      const difficulty = 'advanced';
      const techniques = ['palm-muting', 'alternate-picking'];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: RiffGlassCard(
              name: riffName,
              artist: artist,
              genre: genre,
              difficulty: difficulty,
              targetBpm: 120,
              currentBpm: 80,
              progress: 0.6,
              techniques: techniques,
              showAudioControls: false, // Disable audio controls for testing
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(riffName), findsOneWidget);
      expect(find.text(artist), findsOneWidget);
      expect(find.text(difficulty.toUpperCase()), findsOneWidget);
      expect(find.text(genre.toUpperCase()), findsOneWidget);
      
      // Verify techniques are displayed
      for (final technique in techniques) {
        expect(find.textContaining(technique.replaceAll('-', ' ')), findsOneWidget);
      }
    });

    testWidgets('GlassCard should handle tap events', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final testChild = Text('Tappable Content');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: testChild,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });
  });
}