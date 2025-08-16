import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'spotify_service.dart';
import 'secure_credentials_service.dart';

/// Spotify Playlist Service for importing user playlists
/// Uses Spotify Authorization Code Flow for user authentication
class SpotifyPlaylistService {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _authUrl = 'https://accounts.spotify.com';
  
  final SecureCredentialsService _credentialsService;
  
  String? _userAccessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  
  SpotifyPlaylistService(this._credentialsService);
  
  /// Generate Spotify authorization URL for user login
  Future<String?> generateAuthUrl() async {
    try {
      final clientId = await _credentialsService.getSpotifyClientId();
      if (clientId == null) {
        return null; // Return null instead of throwing exception
      }
      
      final state = _generateRandomString(16);
      final scopes = [
        'playlist-read-private',
        'playlist-read-collaborative',
        'user-library-read',
        'user-top-read',
      ].join(' ');
      
      final params = {
        'response_type': 'code',
        'client_id': clientId,
        'scope': scopes,
        'redirect_uri': 'guitarrapp://spotify-callback',
        'state': state,
        'show_dialog': 'true',
      };
      
      final queryString = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      return '$_authUrl/authorize?$queryString';
    } catch (e) {
      throw SpotifyPlaylistException('Error generating auth URL: $e');
    }
  }
  
  /// Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final clientId = await _credentialsService.getSpotifyClientId();
      final clientSecret = await _credentialsService.getSpotifyClientSecret();
      
      if (clientId == null || clientSecret == null) {
        throw SpotifyPlaylistException('Spotify credentials not configured');
      }
      
      final response = await http.post(
        Uri.parse('$_authUrl/api/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': 'guitarrapp://spotify-callback',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userAccessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        
        // Store tokens securely
        await _credentialsService.storeSpotifyUserTokens(
          accessToken: _userAccessToken!,
          refreshToken: _refreshToken!,
          expiresAt: _tokenExpiry!,
        );
        
        return true;
      } else {
        throw SpotifyPlaylistException('Token exchange failed: ${response.statusCode}');
      }
    } catch (e) {
      throw SpotifyPlaylistException('Error exchanging code for token: $e');
    }
  }
  
  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        // Try to load from secure storage
        final tokens = await _credentialsService.getSpotifyUserTokens();
        if (tokens == null) {
          return false;
        }
        _refreshToken = tokens.refreshToken;
      }
      
      final clientId = await _credentialsService.getSpotifyClientId();
      final clientSecret = await _credentialsService.getSpotifyClientSecret();
      
      if (clientId == null || clientSecret == null) {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_authUrl/api/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userAccessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        
        // Update stored tokens
        await _credentialsService.storeSpotifyUserTokens(
          accessToken: _userAccessToken!,
          refreshToken: _refreshToken!,
          expiresAt: _tokenExpiry!,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get valid user access token
  Future<String?> _getUserAccessToken() async {
    // Check if current token is valid
    if (_userAccessToken != null && 
        _tokenExpiry != null && 
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _userAccessToken;
    }
    
    // Try to refresh token
    if (await _refreshAccessToken()) {
      return _userAccessToken;
    }
    
    // Try to load from storage
    final tokens = await _credentialsService.getSpotifyUserTokens();
    if (tokens != null) {
      _userAccessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      _tokenExpiry = tokens.expiresAt;
      
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _userAccessToken;
      } else if (await _refreshAccessToken()) {
        return _userAccessToken;
      }
    }
    
    return null;
  }
  
  /// Get user's playlists
  Future<List<SpotifyPlaylist>> getUserPlaylists({int limit = 50}) async {
    try {
      final token = await _getUserAccessToken();
      if (token == null) {
        return _getDemoPlaylists(); // Return demo playlists instead of throwing
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/me/playlists?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => SpotifyPlaylist.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        // Token expired, try refresh
        if (await _refreshAccessToken()) {
          return getUserPlaylists(limit: limit);
        }
        throw SpotifyPlaylistException('Authentication failed');
      } else {
        throw SpotifyPlaylistException('Failed to fetch playlists: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SpotifyPlaylistException) rethrow;
      throw SpotifyPlaylistException('Error fetching playlists: $e');
    }
  }
  
  /// Get tracks from a playlist
  Future<List<SpotifyPlaylistTrack>> getPlaylistTracks(String playlistId) async {
    try {
      final token = await _getUserAccessToken();
      if (token == null) {
        throw SpotifyPlaylistException('User not authenticated');
      }
      
      final tracks = <SpotifyPlaylistTrack>[];
      String? nextUrl = '$_baseUrl/playlists/$playlistId/tracks?limit=100';
      
      while (nextUrl != null) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List;
          
          for (final item in items) {
            if (item['track'] != null && item['track']['type'] == 'track') {
              tracks.add(SpotifyPlaylistTrack.fromJson(item));
            }
          }
          
          nextUrl = data['next'];
        } else if (response.statusCode == 401) {
          if (await _refreshAccessToken()) {
            continue; // Retry with new token
          }
          throw SpotifyPlaylistException('Authentication failed');
        } else {
          throw SpotifyPlaylistException('Failed to fetch tracks: ${response.statusCode}');
        }
      }
      
      return tracks;
    } catch (e) {
      if (e is SpotifyPlaylistException) rethrow;
      throw SpotifyPlaylistException('Error fetching playlist tracks: $e');
    }
  }
  
  /// Get user's saved tracks (liked songs)
  Future<List<SpotifyPlaylistTrack>> getUserSavedTracks({int limit = 50}) async {
    try {
      final token = await _getUserAccessToken();
      if (token == null) {
        throw SpotifyPlaylistException('User not authenticated');
      }
      
      final tracks = <SpotifyPlaylistTrack>[];
      String? nextUrl = '$_baseUrl/me/tracks?limit=$limit';
      
      while (nextUrl != null && tracks.length < limit) {
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List;
          
          for (final item in items) {
            if (item['track'] != null) {
              tracks.add(SpotifyPlaylistTrack.fromJson(item));
            }
          }
          
          nextUrl = data['next'];
        } else if (response.statusCode == 401) {
          if (await _refreshAccessToken()) {
            continue;
          }
          throw SpotifyPlaylistException('Authentication failed');
        } else {
          throw SpotifyPlaylistException('Failed to fetch saved tracks: ${response.statusCode}');
        }
      }
      
      return tracks.take(limit).toList();
    } catch (e) {
      if (e is SpotifyPlaylistException) rethrow;
      throw SpotifyPlaylistException('Error fetching saved tracks: $e');
    }
  }
  
  /// Get user's top tracks
  Future<List<SpotifyPlaylistTrack>> getUserTopTracks({
    String timeRange = 'medium_term', // short_term, medium_term, long_term
    int limit = 20,
  }) async {
    try {
      final token = await _getUserAccessToken();
      if (token == null) {
        throw SpotifyPlaylistException('User not authenticated');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/me/top/tracks?time_range=$timeRange&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => SpotifyPlaylistTrack.fromTrack(item)).toList();
      } else if (response.statusCode == 401) {
        if (await _refreshAccessToken()) {
          return getUserTopTracks(timeRange: timeRange, limit: limit);
        }
        throw SpotifyPlaylistException('Authentication failed');
      } else {
        throw SpotifyPlaylistException('Failed to fetch top tracks: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SpotifyPlaylistException) rethrow;
      throw SpotifyPlaylistException('Error fetching top tracks: $e');
    }
  }
  
  /// Filter tracks by guitar-friendliness using ML-like scoring
  List<SpotifyPlaylistTrack> filterGuitarTracks(List<SpotifyPlaylistTrack> tracks) {
    final guitarTracks = <SpotifyPlaylistTrack>[];
    
    for (final track in tracks) {
      final score = _calculateGuitarScore(track);
      if (score > 0.6) { // 60% guitar-friendly threshold
        guitarTracks.add(track.copyWith(guitarScore: score));
      }
    }
    
    // Sort by guitar score (highest first)
    guitarTracks.sort((a, b) => b.guitarScore.compareTo(a.guitarScore));
    
    return guitarTracks;
  }
  
  /// Calculate guitar-friendliness score for a track
  double _calculateGuitarScore(SpotifyPlaylistTrack track) {
    double score = 0.5; // Base score
    
    // Genre-based scoring
    final guitarGenres = [
      'rock', 'metal', 'alternative', 'indie', 'punk', 'blues', 
      'country', 'folk', 'acoustic', 'grunge', 'hard rock'
    ];
    
    final trackData = track.track.toLowerCase();
    final artistData = track.artist.toLowerCase();
    
    for (final genre in guitarGenres) {
      if (trackData.contains(genre) || artistData.contains(genre)) {
        score += 0.2;
      }
    }
    
    // Artist-based scoring (known guitar-centric artists)
    final guitarArtists = [
      'metallica', 'led zeppelin', 'pink floyd', 'ac/dc', 'black sabbath',
      'deep purple', 'iron maiden', 'guns n roses', 'nirvana', 'pearl jam',
      'foo fighters', 'red hot chili peppers', 'green day', 'the beatles',
      'eric clapton', 'jimi hendrix', 'stevie ray vaughan', 'bb king'
    ];
    
    for (final artist in guitarArtists) {
      if (artistData.contains(artist)) {
        score += 0.3;
        break;
      }
    }
    
    // Song characteristics
    if (trackData.contains('guitar') || 
        trackData.contains('riff') || 
        trackData.contains('solo')) {
      score += 0.2;
    }
    
    // Penalize non-guitar genres
    final nonGuitarGenres = ['electronic', 'edm', 'techno', 'house', 'dubstep'];
    for (final genre in nonGuitarGenres) {
      if (trackData.contains(genre) || artistData.contains(genre)) {
        score -= 0.3;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Generate random string for state parameter
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getUserAccessToken();
    return token != null;
  }
  
  /// Clear user authentication
  Future<void> logout() async {
    _userAccessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    await _credentialsService.clearSpotifyUserTokens();
  }
  
  /// Generate demo playlists when Spotify is not available
  List<SpotifyPlaylist> _getDemoPlaylists() {
    return [
      SpotifyPlaylist(
        id: 'demo_playlist_1',
        name: 'Guitar Learning Essentials',
        description: 'Perfect songs for learning guitar basics (Demo Mode)',
        imageUrl: null,
        trackCount: 15,
        isPublic: true,
        ownerName: 'GuitarrApp',
      ),
      SpotifyPlaylist(
        id: 'demo_playlist_2',
        name: 'Easy Acoustic Songs',
        description: 'Simple acoustic songs for beginners (Demo Mode)',
        imageUrl: null,
        trackCount: 12,
        isPublic: true,
        ownerName: 'GuitarrApp',
      ),
      SpotifyPlaylist(
        id: 'demo_playlist_3',
        name: 'Classic Rock Riffs',
        description: 'Iconic rock riffs to master (Demo Mode)',
        imageUrl: null,
        trackCount: 20,
        isPublic: true,
        ownerName: 'GuitarrApp',
      ),
    ];
  }
}

// Data Models
class SpotifyPlaylist {
  final String id;
  final String name;
  final String description;
  final int trackCount;
  final String? imageUrl;
  final bool isPublic;
  final String ownerName;
  
  const SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.trackCount,
    this.imageUrl,
    required this.isPublic,
    required this.ownerName,
  });
  
  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty 
        ? images.first['url'] as String?
        : null;
    
    return SpotifyPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      trackCount: json['tracks']['total'] as int,
      imageUrl: imageUrl,
      isPublic: json['public'] as bool,
      ownerName: json['owner']['display_name'] as String,
    );
  }
}

class SpotifyPlaylistTrack {
  final String id;
  final String track;
  final String artist;
  final String? previewUrl;
  final int durationMs;
  final String? albumImageUrl;
  final String spotifyUrl;
  final DateTime addedAt;
  final double guitarScore;
  
  const SpotifyPlaylistTrack({
    required this.id,
    required this.track,
    required this.artist,
    this.previewUrl,
    required this.durationMs,
    this.albumImageUrl,
    required this.spotifyUrl,
    required this.addedAt,
    this.guitarScore = 0.0,
  });
  
  factory SpotifyPlaylistTrack.fromJson(Map<String, dynamic> json) {
    final trackData = json['track'] as Map<String, dynamic>;
    final artists = trackData['artists'] as List;
    final artistName = artists.isNotEmpty ? artists.first['name'] : 'Unknown Artist';
    
    final album = trackData['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty 
        ? images.first['url'] as String?
        : null;
    
    return SpotifyPlaylistTrack(
      id: trackData['id'] as String,
      track: trackData['name'] as String,
      artist: artistName,
      previewUrl: trackData['preview_url'] as String?,
      durationMs: trackData['duration_ms'] as int,
      albumImageUrl: imageUrl,
      spotifyUrl: trackData['external_urls']['spotify'] as String,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
  
  factory SpotifyPlaylistTrack.fromTrack(Map<String, dynamic> trackData) {
    final artists = trackData['artists'] as List;
    final artistName = artists.isNotEmpty ? artists.first['name'] : 'Unknown Artist';
    
    final album = trackData['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty 
        ? images.first['url'] as String?
        : null;
    
    return SpotifyPlaylistTrack(
      id: trackData['id'] as String,
      track: trackData['name'] as String,
      artist: artistName,
      previewUrl: trackData['preview_url'] as String?,
      durationMs: trackData['duration_ms'] as int,
      albumImageUrl: imageUrl,
      spotifyUrl: trackData['external_urls']['spotify'] as String,
      addedAt: DateTime.now(), // No added_at for top tracks
    );
  }
  
  SpotifyPlaylistTrack copyWith({
    String? id,
    String? track,
    String? artist,
    String? previewUrl,
    int? durationMs,
    String? albumImageUrl,
    String? spotifyUrl,
    DateTime? addedAt,
    double? guitarScore,
  }) {
    return SpotifyPlaylistTrack(
      id: id ?? this.id,
      track: track ?? this.track,
      artist: artist ?? this.artist,
      previewUrl: previewUrl ?? this.previewUrl,
      durationMs: durationMs ?? this.durationMs,
      albumImageUrl: albumImageUrl ?? this.albumImageUrl,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      addedAt: addedAt ?? this.addedAt,
      guitarScore: guitarScore ?? this.guitarScore,
    );
  }
  
  bool get hasPreview => previewUrl != null;
  Duration get duration => Duration(milliseconds: durationMs);
}

class SpotifyPlaylistException implements Exception {
  final String message;
  
  const SpotifyPlaylistException(this.message);
  
  @override
  String toString() => 'SpotifyPlaylistException: $message';
}

// Riverpod providers
final spotifyPlaylistServiceProvider = Provider<SpotifyPlaylistService>((ref) {
  final credentialsService = ref.read(secureCredentialsServiceProvider);
  return SpotifyPlaylistService(credentialsService);
});

final userPlaylistsProvider = FutureProvider<List<SpotifyPlaylist>>((ref) async {
  final service = ref.read(spotifyPlaylistServiceProvider);
  return service.getUserPlaylists();
});

final userSavedTracksProvider = FutureProvider<List<SpotifyPlaylistTrack>>((ref) async {
  final service = ref.read(spotifyPlaylistServiceProvider);
  return service.getUserSavedTracks(limit: 50);
});

final userTopTracksProvider = FutureProvider<List<SpotifyPlaylistTrack>>((ref) async {
  final service = ref.read(spotifyPlaylistServiceProvider);
  return service.getUserTopTracks(limit: 20);
});

final playlistTracksProvider = FutureProvider.family<List<SpotifyPlaylistTrack>, String>((ref, playlistId) async {
  final service = ref.read(spotifyPlaylistServiceProvider);
  return service.getPlaylistTracks(playlistId);
});

final guitarTracksProvider = FutureProvider<List<SpotifyPlaylistTrack>>((ref) async {
  final service = ref.read(spotifyPlaylistServiceProvider);
  final savedTracks = await ref.read(userSavedTracksProvider.future);
  final topTracks = await ref.read(userTopTracksProvider.future);
  
  final allTracks = [...savedTracks, ...topTracks];
  return service.filterGuitarTracks(allTracks);
});