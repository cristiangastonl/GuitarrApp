import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'secure_credentials_service.dart';

/// Spotify Web API Service for preview clips and track information
/// 
/// Uses the public Spotify Web API to fetch 30-second preview clips
/// Uses secure credential storage for API authentication
class SpotifyService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  
  final SecureCredentialsService _credentialsService;
  
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  SpotifyService(this._credentialsService);
  
  /// Get access token for Spotify Web API (Client Credentials flow)
  Future<String?> _getAccessToken() async {
    // Check if current token is still valid
    if (_accessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }
    
    try {
      // Obtener credenciales de almacenamiento seguro
      final clientId = await _credentialsService.getSpotifyClientId();
      final clientSecret = await _credentialsService.getSpotifyClientSecret();
      
      if (clientId == null || clientSecret == null) {
        throw SecureCredentialsException('Credenciales de Spotify no configuradas');
      }
      
      // Verificar integridad de las credenciales
      final integrityOk = await _credentialsService.verifyCredentialsIntegrity();
      if (!integrityOk) {
        throw SecureCredentialsException('Integridad de credenciales comprometida');
      }
      
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // 1 minute buffer
        
        return _accessToken;
      } else {
        throw SpotifyApiException('Token request failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SecureCredentialsException || e is SpotifyApiException) {
        rethrow;
      }
      throw SpotifyApiException('Error getting Spotify access token: $e');
    }
    
    return null;
  }
  
  /// Search for a track and get preview URL
  Future<SpotifyTrackPreview?> searchTrackPreview(String artist, String track) async {
    // Clean track name by removing descriptive parts after dashes
    String cleanTrack = track;
    if (track.contains(' - ')) {
      cleanTrack = track.split(' - ')[0].trim();
    }
    
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw SpotifyApiException('No access token available');
      }
      
      // Search with higher limit to find versions with previews
      final query = Uri.encodeComponent('artist:$artist track:$cleanTrack');
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&type=track&limit=5'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['items'] as List;
        
        if (tracks.isNotEmpty) {
          // Look for a track with preview URL first
          for (final trackData in tracks) {
            final preview = SpotifyTrackPreview.fromJson(trackData);
            if (preview.hasPreview) {
              return preview;
            }
          }
          
          // If no preview found, return first track anyway
          final firstTrack = SpotifyTrackPreview.fromJson(tracks.first);
          return firstTrack;
        }
      } else {
        throw SpotifyApiException('Search request failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SpotifyApiException || e is SecureCredentialsException) {
        rethrow;
      }
      throw SpotifyApiException('Error searching Spotify track: $e');
    }
    
    return null;
  }
  
  /// Get multiple track previews in batch
  Future<List<SpotifyTrackPreview>> searchMultipleTrackPreviews(
    List<({String artist, String track})> searches,
  ) async {
    final results = <SpotifyTrackPreview>[];
    
    for (final search in searches) {
      final preview = await searchTrackPreview(search.artist, search.track);
      if (preview != null) {
        results.add(preview);
      }
    }
    
    return results;
  }
}

/// Spotify track preview data model
class SpotifyTrackPreview {
  final String id;
  final String name;
  final String artist;
  final String? previewUrl;
  final int durationMs;
  final String? albumImageUrl;
  final String spotifyUrl;
  
  const SpotifyTrackPreview({
    required this.id,
    required this.name,
    required this.artist,
    this.previewUrl,
    required this.durationMs,
    this.albumImageUrl,
    required this.spotifyUrl,
  });
  
  factory SpotifyTrackPreview.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List;
    final artistName = artists.isNotEmpty ? artists.first['name'] : 'Unknown Artist';
    
    final album = json['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty 
        ? images.first['url'] as String?
        : null;
    
    return SpotifyTrackPreview(
      id: json['id'],
      name: json['name'],
      artist: artistName,
      previewUrl: json['preview_url'],
      durationMs: json['duration_ms'],
      albumImageUrl: imageUrl,
      spotifyUrl: json['external_urls']['spotify'],
    );
  }
  
  /// Check if preview is available
  bool get hasPreview => previewUrl != null;
  
  /// Get preview duration (always 30 seconds for Spotify)
  Duration get previewDuration => const Duration(seconds: 30);
  
  /// Get full track duration
  Duration get fullDuration => Duration(milliseconds: durationMs);
}

/// Excepción personalizada para errores de Spotify API
class SpotifyApiException implements Exception {
  final String message;
  
  const SpotifyApiException(this.message);
  
  @override
  String toString() => 'SpotifyApiException: $message';
}

/// Riverpod provider for SpotifyService
final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  final credentialsService = ref.read(secureCredentialsServiceProvider);
  return SpotifyService(credentialsService);
});

/// Provider for track preview cache
final trackPreviewCacheProvider = StateProvider<Map<String, SpotifyTrackPreview>>((ref) {
  return {};
});

/// Provider to get a specific track preview
final trackPreviewProvider = FutureProvider.family<SpotifyTrackPreview?, ({String artist, String track})>((ref, search) async {
  final spotifyService = ref.read(spotifyServiceProvider);
  final cache = ref.read(trackPreviewCacheProvider.notifier);
  
  final cacheKey = '${search.artist}_${search.track}';
  final cachedPreview = ref.read(trackPreviewCacheProvider)[cacheKey];
  
  if (cachedPreview != null) {
    return cachedPreview;
  }
  
  final preview = await spotifyService.searchTrackPreview(search.artist, search.track);
  
  if (preview != null) {
    cache.update((state) => {...state, cacheKey: preview});
  }
  
  return preview;
});