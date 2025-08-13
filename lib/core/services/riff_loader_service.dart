import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../storage/storage.dart';

class RiffLoaderService {
  static const String _riffsAssetPath = 'assets/data/riffs_database.json';

  static Future<List<SongRiff>> loadInitialRiffs() async {
    try {
      final String jsonString = await rootBundle.loadString(_riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> riffsData = data['riffs'] as List<dynamic>;
      final List<dynamic> exercisesData = data['exercises'] as List<dynamic>;
      
      final List<SongRiff> allRiffs = [
        ...riffsData.map((riffJson) => SongRiff.fromJson(riffJson as Map<String, dynamic>)),
        ...exercisesData.map((exerciseJson) => SongRiff.fromJson(exerciseJson as Map<String, dynamic>)),
      ];
      
      return allRiffs;
    } catch (e) {
      throw Exception('Error loading riffs from assets: $e');
    }
  }

  static Future<void> initializeDatabase() async {
    try {
      // Check if database already has riffs
      final existingRiffs = await DatabaseHelper.getAllSongRiffs();
      
      if (existingRiffs.isEmpty) {
        // Load and insert initial riffs
        final riffs = await loadInitialRiffs();
        
        for (final riff in riffs) {
          await DatabaseHelper.insertSongRiff(riff);
        }
        
        print('✅ Database initialized with ${riffs.length} riffs');
      } else {
        print('📊 Database already contains ${existingRiffs.length} riffs');
      }
    } catch (e) {
      throw Exception('Error initializing database: $e');
    }
  }

  static Future<Map<String, dynamic>> getRiffsMetadata() async {
    try {
      final String jsonString = await rootBundle.loadString(_riffsAssetPath);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      return data['metadata'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading riffs metadata: $e');
    }
  }

  static Future<List<SongRiff>> getRiffsByDifficulty(String difficulty) async {
    try {
      return await DatabaseHelper.getSongRiffsByDifficulty(difficulty);
    } catch (e) {
      throw Exception('Error getting riffs by difficulty: $e');
    }
  }

  static Future<List<SongRiff>> getRiffsByGenre(String genre) async {
    try {
      return await DatabaseHelper.getSongRiffsByGenre(genre);
    } catch (e) {
      throw Exception('Error getting riffs by genre: $e');
    }
  }

  static Future<List<SongRiff>> searchRiffs(String query) async {
    try {
      final allRiffs = await DatabaseHelper.getAllSongRiffs();
      final lowercaseQuery = query.toLowerCase();
      
      return allRiffs.where((riff) {
        return riff.name.toLowerCase().contains(lowercaseQuery) ||
               riff.artistName.toLowerCase().contains(lowercaseQuery) ||
               riff.genre.toLowerCase().contains(lowercaseQuery) ||
               riff.techniques.any((technique) => 
                   technique.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      throw Exception('Error searching riffs: $e');
    }
  }

  static Future<List<String>> getAvailableGenres() async {
    try {
      final allRiffs = await DatabaseHelper.getAllSongRiffs();
      final genres = allRiffs.map((riff) => riff.genre).toSet().toList();
      genres.sort();
      return genres;
    } catch (e) {
      throw Exception('Error getting available genres: $e');
    }
  }

  static Future<List<String>> getAvailableTechniques() async {
    try {
      final allRiffs = await DatabaseHelper.getAllSongRiffs();
      final Set<String> techniques = {};
      
      for (final riff in allRiffs) {
        techniques.addAll(riff.techniques);
      }
      
      final techniquesList = techniques.toList();
      techniquesList.sort();
      return techniquesList;
    } catch (e) {
      throw Exception('Error getting available techniques: $e');
    }
  }

  static Future<Map<String, int>> getRiffStatistics() async {
    try {
      final allRiffs = await DatabaseHelper.getAllSongRiffs();
      
      final Map<String, int> stats = {
        'total': allRiffs.length,
        'easy': 0,
        'medium': 0,
        'hard': 0,
      };
      
      final Map<String, int> genreStats = {};
      
      for (final riff in allRiffs) {
        // Difficulty stats
        if (stats.containsKey(riff.difficulty)) {
          stats[riff.difficulty] = stats[riff.difficulty]! + 1;
        }
        
        // Genre stats
        genreStats[riff.genre] = (genreStats[riff.genre] ?? 0) + 1;
      }
      
      stats.addAll(genreStats);
      return stats;
    } catch (e) {
      throw Exception('Error getting riff statistics: $e');
    }
  }

  static Future<List<SongRiff>> getRecommendedRiffs({
    String? userSkillLevel,
    List<String>? preferredGenres,
    int limit = 5,
  }) async {
    try {
      final allRiffs = await DatabaseHelper.getAllSongRiffs();
      List<SongRiff> filteredRiffs = allRiffs;
      
      // Filter by skill level if provided
      if (userSkillLevel != null) {
        final skillOrder = ['easy', 'medium', 'hard'];
        final userSkillIndex = skillOrder.indexOf(userSkillLevel);
        
        if (userSkillIndex != -1) {
          filteredRiffs = filteredRiffs.where((riff) {
            final riffSkillIndex = skillOrder.indexOf(riff.difficulty);
            return riffSkillIndex <= userSkillIndex + 1; // Allow one level up
          }).toList();
        }
      }
      
      // Filter by preferred genres if provided
      if (preferredGenres != null && preferredGenres.isNotEmpty) {
        filteredRiffs = filteredRiffs.where((riff) {
          return preferredGenres.contains(riff.genre);
        }).toList();
      }
      
      // Sort by difficulty and return limited results
      filteredRiffs.sort((a, b) {
        final skillOrder = ['easy', 'medium', 'hard'];
        return skillOrder.indexOf(a.difficulty).compareTo(skillOrder.indexOf(b.difficulty));
      });
      
      return filteredRiffs.take(limit).toList();
    } catch (e) {
      throw Exception('Error getting recommended riffs: $e');
    }
  }

  static Future<bool> updateRiffProgress(String riffId, int currentBpm, double accuracy) async {
    try {
      // This could be extended to update user progress tracking
      // For now, just update the last used riff in preferences
      await PreferencesHelper.setLastUsedRiffId(riffId);
      await PreferencesHelper.setLastBpm(currentBpm);
      
      return true;
    } catch (e) {
      print('Error updating riff progress: $e');
      return false;
    }
  }
}