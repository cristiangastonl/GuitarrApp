import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  group('Content Validation Tests', () {
    test('should load and validate all 18 riffs from JSON', () async {
      // Arrange
      const String riffsAssetPath = 'assets/data/riffs_database.json';
      
      // Act
      final String jsonString = await rootBundle.loadString(riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> riffsData = data['riffs'] as List<dynamic>;
      final List<dynamic> exercisesData = data['exercises'] as List<dynamic>;
      final Map<String, dynamic> metadata = data['metadata'] as Map<String, dynamic>;
      
      // Assert - Total content validation
      expect(riffsData.length, equals(16), reason: 'Should have 16 riffs (10 original + 6 new)');
      expect(exercisesData.length, equals(2), reason: 'Should have 2 exercises');
      expect(metadata['totalRiffs'], equals(16), reason: 'Metadata should reflect correct riff count');
      expect(metadata['totalExercises'], equals(2), reason: 'Metadata should reflect correct exercise count');
      
      // Assert - New riffs are present
      final newRiffIds = [
        'californication_verse',
        'hotel_california_intro', 
        'wonderwall_chorus',
        'purple_haze_intro',
        'creep_chorus',
        'cliffs_of_dover_intro'
      ];
      
      final loadedRiffIds = riffsData.map((riff) => riff['id'] as String).toList();
      
      for (final newRiffId in newRiffIds) {
        expect(loadedRiffIds.contains(newRiffId), true, 
               reason: 'New riff $newRiffId should be present in database');
      }
      
      // Assert - Validate structure of new riffs
      for (final riffData in riffsData) {
        final riff = riffData as Map<String, dynamic>;
        
        // Required fields validation
        expect(riff.containsKey('id'), true, reason: 'Riff should have id field');
        expect(riff.containsKey('name'), true, reason: 'Riff should have name field');
        expect(riff.containsKey('artistName'), true, reason: 'Riff should have artistName field');
        expect(riff.containsKey('genre'), true, reason: 'Riff should have genre field');
        expect(riff.containsKey('difficulty'), true, reason: 'Riff should have difficulty field');
        expect(riff.containsKey('targetBpm'), true, reason: 'Riff should have targetBpm field');
        expect(riff.containsKey('startingBpm'), true, reason: 'Riff should have startingBpm field');
        expect(riff.containsKey('techniques'), true, reason: 'Riff should have techniques field');
        expect(riff.containsKey('tabNotation'), true, reason: 'Riff should have tabNotation field');
        expect(riff.containsKey('description'), true, reason: 'Riff should have description field');
        
        // Data type validation
        expect(riff['id'] is String, true, reason: 'ID should be string');
        expect(riff['name'] is String, true, reason: 'Name should be string');
        expect(riff['targetBpm'] is int, true, reason: 'Target BPM should be integer');
        expect(riff['startingBpm'] is int, true, reason: 'Starting BPM should be integer');
        expect(riff['techniques'] is List, true, reason: 'Techniques should be list');
        
        // Business logic validation
        expect(riff['targetBpm'] > riff['startingBpm'], true, 
               reason: 'Target BPM should be higher than starting BPM for riff ${riff['id']}');
        expect(['easy', 'medium', 'hard'].contains(riff['difficulty']), true,
               reason: 'Difficulty should be valid for riff ${riff['id']}');
      }
    });
    
    test('should validate new genres and techniques are properly added', () async {
      // Arrange
      const String riffsAssetPath = 'assets/data/riffs_database.json';
      
      // Act
      final String jsonString = await rootBundle.loadString(riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final Map<String, dynamic> metadata = data['metadata'] as Map<String, dynamic>;
      
      // Assert - New genres added
      final List<String> genres = (metadata['genres'] as List).cast<String>();
      expect(genres.contains('blues'), true, reason: 'Should include blues genre');
      expect(genres.contains('alternative'), true, reason: 'Should include alternative genre');
      expect(genres.contains('instrumental'), true, reason: 'Should include instrumental genre');
      
      // Assert - New techniques added
      final List<String> techniques = (metadata['techniques'] as List).cast<String>();
      final newTechniques = [
        'chord-progression',
        'muted-strumming', 
        'classical-style',
        'strumming',
        'capo',
        'octave-chord',
        'hendrix-style',
        'clean-distorted',
        'legato',
        'sweep-picking'
      ];
      
      for (final technique in newTechniques) {
        expect(techniques.contains(technique), true, 
               reason: 'Should include new technique: $technique');
      }
    });
    
    test('should validate professional quality of new riffs', () async {
      // Arrange
      const String riffsAssetPath = 'assets/data/riffs_database.json';
      
      // Act
      final String jsonString = await rootBundle.loadString(riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> riffsData = data['riffs'] as List<dynamic>;
      
      // Filter to new riffs only
      final newRiffIds = [
        'californication_verse',
        'hotel_california_intro', 
        'wonderwall_chorus',
        'purple_haze_intro',
        'creep_chorus',
        'cliffs_of_dover_intro'
      ];
      
      final newRiffs = riffsData.where((riff) => 
        newRiffIds.contains(riff['id'])).toList();
      
      expect(newRiffs.length, equals(6), reason: 'Should find all 6 new riffs');
      
      // Assert - Professional quality checks
      for (final riffData in newRiffs) {
        final riff = riffData as Map<String, dynamic>;
        
        // Description quality
        expect((riff['description'] as String).length > 50, true,
               reason: 'Riff ${riff['id']} should have detailed description');
        
        // Technique diversity
        expect((riff['techniques'] as List).length >= 2, true,
               reason: 'Riff ${riff['id']} should have multiple techniques');
        
        // Tab notation present
        expect((riff['tabNotation'] as String).contains('|'), true,
               reason: 'Riff ${riff['id']} should have proper tab notation');
        
        // Realistic BPM ranges
        expect(riff['startingBpm'] >= 45 && riff['startingBpm'] <= 100, true,
               reason: 'Riff ${riff['id']} should have realistic starting BPM');
        expect(riff['targetBpm'] >= 80 && riff['targetBpm'] <= 200, true,
               reason: 'Riff ${riff['id']} should have realistic target BPM');
        
        // Artist and song names
        expect((riff['name'] as String).length > 5, true,
               reason: 'Riff ${riff['id']} should have proper song name');
        expect((riff['artistName'] as String).length > 3, true,
               reason: 'Riff ${riff['id']} should have proper artist name');
      }
    });
    
    test('should validate difficulty distribution is balanced', () async {
      // Arrange
      const String riffsAssetPath = 'assets/data/riffs_database.json';
      
      // Act
      final String jsonString = await rootBundle.loadString(riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> riffsData = data['riffs'] as List<dynamic>;
      
      // Count difficulties
      final difficultyCount = <String, int>{};
      for (final riffData in riffsData) {
        final difficulty = riffData['difficulty'] as String;
        difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;
      }
      
      // Assert - Balanced distribution
      expect(difficultyCount['easy']! >= 3, true, 
             reason: 'Should have at least 3 easy riffs');
      expect(difficultyCount['medium']! >= 4, true, 
             reason: 'Should have at least 4 medium riffs');
      expect(difficultyCount['hard']! >= 3, true, 
             reason: 'Should have at least 3 hard riffs');
      
      print('Difficulty distribution: $difficultyCount');
    });
  });
}