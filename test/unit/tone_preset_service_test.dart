import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/core/services/tone_preset_service.dart';
import '../../lib/core/models/tone_preset.dart';
import '../../lib/core/models/song_riff.dart';
import '../../lib/core/storage/database_helper.dart';

// Generate mocks
@GenerateNiceMocks([MockSpec<DatabaseHelper>()])
import 'tone_preset_service_test.mocks.dart';

void main() {
  group('TonePresetService Tests', () {
    late TonePresetService service;
    late MockDatabaseHelper mockDatabaseHelper;

    setUp(() {
      service = TonePresetService();
      mockDatabaseHelper = MockDatabaseHelper();
    });

    group('getAllPresets', () {
      test('should return all presets from database', () async {
        // Arrange
        final expectedPresets = [
          TonePreset.createRockPreset(),
          TonePreset.createMetalPreset(),
          TonePreset.createCleanPreset(),
        ];
        
        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => expectedPresets);

        // Act
        final result = await service.getAllPresets();

        // Assert
        expect(result, equals(expectedPresets));
        expect(result.length, equals(3));
      });

      test('should handle empty database gracefully', () async {
        // Arrange
        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => []);

        // Act
        final result = await service.getAllPresets();

        // Assert
        expect(result, isEmpty);
      });

      test('should handle database errors', () async {
        // Arrange
        when(mockDatabaseHelper.getAllTonePresets())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() => service.getAllPresets(), throwsException);
      });
    });

    group('getPresetsByGenre', () {
      test('should return presets filtered by genre', () async {
        // Arrange
        final rockPresets = [TonePreset.createRockPreset()];
        
        when(mockDatabaseHelper.getTonePresetsByGenre('rock'))
            .thenAnswer((_) async => rockPresets);

        // Act
        final result = await service.getPresetsByGenre('rock');

        // Assert
        expect(result, equals(rockPresets));
        expect(result.length, equals(1));
        expect(result.first.genre, equals('rock'));
      });

      test('should return empty list for non-existent genre', () async {
        // Arrange
        when(mockDatabaseHelper.getTonePresetsByGenre('jazz'))
            .thenAnswer((_) async => []);

        // Act
        final result = await service.getPresetsByGenre('jazz');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('createCustomPreset', () {
      test('should create and save custom preset successfully', () async {
        // Arrange
        const presetName = 'My Custom Preset';
        const description = 'Custom description';
        const genre = 'rock';
        const ampModel = 'marshall_plexi';
        const eqSettings = {
          'bass': 0.7,
          'mid': 0.5,
          'treble': 0.8,
          'presence': 0.6,
        };
        const effects = {
          'distortion': 0.6,
          'reverb': 0.3,
          'delay': 0.1,
          'chorus': 0.0,
        };

        when(mockDatabaseHelper.insertTonePreset(any))
            .thenAnswer((_) async => 1);

        // Act
        final result = await service.createCustomPreset(
          name: presetName,
          description: description,
          genre: genre,
          ampModel: ampModel,
          eqSettings: eqSettings,
          effects: effects,
          gain: 0.8,
          volume: 0.7,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.name, equals(presetName));
        expect(result.description, equals(description));
        expect(result.genre, equals(genre));
        expect(result.ampModel, equals(ampModel));
        expect(result.isCustom, isTrue);
        expect(result.isDefault, isFalse);
        
        verify(mockDatabaseHelper.insertTonePreset(any)).called(1);
      });

      test('should handle preset creation failure', () async {
        // Arrange
        when(mockDatabaseHelper.insertTonePreset(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await service.createCustomPreset(
          name: 'Test Preset',
          description: 'Test description',
          genre: 'rock',
          ampModel: 'marshall_plexi',
          eqSettings: const {'bass': 0.5},
          effects: const {'distortion': 0.5},
          gain: 0.5,
          volume: 0.5,
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('getRecommendationsForRiff', () {
      test('should return appropriate presets for metal riff', () async {
        // Arrange
        final metalRiff = SongRiff(
          id: 'test_riff',
          name: 'Heavy Metal Riff',
          artistName: 'Test Artist',
          genre: 'metal',
          difficulty: 'advanced',
          targetBpm: 120,
          startingBpm: 80,
          techniques: ['palm-muting', 'power-chords'],
          tabNotation: 'E|--0-3-0--|',
          audioPath: '/audio/test.mp3',
          description: 'Heavy metal riff',
          durationSeconds: 30,
          hasGhostNotes: false,
          createdAt: DateTime.now(),
        );

        final allPresets = [
          TonePreset.createMetalPreset(),
          TonePreset.createRockPreset(),
          TonePreset.createCleanPreset(),
        ];

        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => allPresets);

        // Act
        final result = await service.getRecommendationsForRiff(metalRiff);

        // Assert
        expect(result, isNotEmpty);
        // Metal preset should be first (highest score)
        expect(result.first.genre, equals('metal'));
      });

      test('should handle riff with no matching presets', () async {
        // Arrange
        final unknownRiff = SongRiff(
          id: 'unknown_riff',
          name: 'Unknown Genre Riff',
          artistName: 'Test Artist',
          genre: 'unknown',
          difficulty: 'beginner',
          targetBpm: 60,
          startingBpm: 60,
          techniques: [],
          tabNotation: 'E|--0--|',
          audioPath: '/audio/test.mp3',
          description: 'Unknown genre riff',
          durationSeconds: 10,
          hasGhostNotes: false,
          createdAt: DateTime.now(),
        );

        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => []);

        // Act
        final result = await service.getRecommendationsForRiff(unknownRiff);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('comparePresets', () {
      test('should correctly compare two different presets', () {
        // Arrange
        final preset1 = TonePreset.createRockPreset();
        final preset2 = TonePreset.createMetalPreset();

        // Act
        final comparison = service.comparePresets(preset1, preset2);

        // Assert
        expect(comparison, isNotNull);
        expect(comparison['differences'], isNotNull);
        expect(comparison['differences']['eq'], isNotNull);
        expect(comparison['differences']['effects'], isNotNull);
        expect(comparison['differences']['gain'], isA<double>());
        expect(comparison['differences']['volume'], isA<double>());
      });

      test('should return minimal differences for identical presets', () {
        // Arrange
        final preset1 = TonePreset.createRockPreset();
        final preset2 = TonePreset.createRockPreset();

        // Act
        final comparison = service.comparePresets(preset1, preset2);

        // Assert
        expect(comparison['differences']['gain'], equals(0.0));
        expect(comparison['differences']['volume'], equals(0.0));
      });
    });

    group('getPresetsForEquipment', () {
      test('should return compatible presets for equipment', () async {
        // Arrange
        final allPresets = [
          TonePreset.createRockPreset(),
          TonePreset.createMetalPreset(),
          TonePreset.createCleanPreset(),
        ];

        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => allPresets);

        // Act
        final result = await service.getPresetsForEquipment(
          guitarType: 'electric',
          ampType: 'tube',
          genre: 'rock',
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, lessThanOrEqualTo(allPresets.length));
      });

      test('should filter by genre when specified', () async {
        // Arrange
        final allPresets = [
          TonePreset.createRockPreset(),
          TonePreset.createMetalPreset(),
        ];

        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => allPresets);

        // Act
        final result = await service.getPresetsForEquipment(
          guitarType: 'electric',
          ampType: 'tube',
          genre: 'rock',
        );

        // Assert
        expect(result, isNotEmpty);
        // Should prioritize rock presets
        if (result.isNotEmpty) {
          expect(result.first.genre, equals('rock'));
        }
      });
    });

    group('getPresetAnalytics', () {
      test('should return analytics for presets', () async {
        // Arrange
        final presets = [
          TonePreset.createRockPreset(),
          TonePreset.createMetalPreset(),
          TonePreset.createCleanPreset(),
        ];

        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => presets);

        // Act
        final analytics = await service.getPresetAnalytics();

        // Assert
        expect(analytics, isNotNull);
        expect(analytics['totalPresets'], equals(3));
        expect(analytics['genreDistribution'], isNotNull);
        expect(analytics['averageGain'], isA<double>());
        expect(analytics['averageVolume'], isA<double>());
      });

      test('should handle empty preset list', () async {
        // Arrange
        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => []);

        // Act
        final analytics = await service.getPresetAnalytics();

        // Assert
        expect(analytics['totalPresets'], equals(0));
        expect(analytics['genreDistribution'], isEmpty);
        expect(analytics['averageGain'], equals(0.0));
        expect(analytics['averageVolume'], equals(0.0));
      });
    });

    group('edge cases and error handling', () {
      test('should handle null values gracefully', () async {
        // Arrange
        when(mockDatabaseHelper.getAllTonePresets())
            .thenAnswer((_) async => []);

        // Act & Assert
        expect(() => service.getPresetsByGenre(''), returnsNormally);
        expect(() => service.getPresetsForEquipment(
          guitarType: '',
          ampType: '',
        ), returnsNormally);
      });

      test('should validate preset parameters', () async {
        // Act & Assert
        final result = await service.createCustomPreset(
          name: '', // Invalid name
          description: 'Test',
          genre: 'rock',
          ampModel: 'marshall_plexi',
          eqSettings: const {},
          effects: const {},
          gain: 0.5,
          volume: 0.5,
        );

        expect(result, isNull); // Should fail validation
      });
    });
  });
}