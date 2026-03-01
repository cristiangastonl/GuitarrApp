import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiCoachService {
  static GeminiCoachService? _instance;
  GenerativeModel? _model;
  final Map<String, String> _cache = {};

  GeminiCoachService._();

  factory GeminiCoachService() {
    _instance ??= GeminiCoachService._();
    return _instance!;
  }

  bool get isAvailable => _model != null;

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(
        'Eres un profesor de guitarra motivacional y amigable. '
        'Respondes en español. Maximo 2 oraciones cortas. '
        'Usa un tono positivo y alentador. '
        'Da consejos practicos cuando el alumno falla.',
      ),
    );
  }

  /// Get a cache key based on accuracy bucket, chord, and combo range
  String _cacheKey(String chord, double accuracy, int combo) {
    // Bucket accuracy into ranges of 10%
    final bucket = (accuracy * 10).round();
    // Bucket combo into ranges
    final comboBucket = combo < 3 ? 0 : combo < 6 ? 1 : 2;
    return '$chord|$bucket|$comboBucket';
  }

  /// Get AI feedback for a chord attempt.
  /// Returns null if unavailable or on timeout.
  Future<String?> getFeedback({
    required String chordName,
    required double accuracy,
    required String simpleFeedback,
    required int combo,
    required int currentAttempt,
    required int totalAttempts,
    required double averageAccuracy,
  }) async {
    if (_model == null) return null;

    // Check cache
    final key = _cacheKey(chordName, accuracy, combo);
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final prompt =
          'Acorde: $chordName. Precision: ${(accuracy * 100).round()}%. '
          'Resultado: $simpleFeedback. '
          'Combo: $combo. Intento $currentAttempt de $totalAttempts. '
          'Promedio: ${(averageAccuracy * 100).round()}%. '
          'Da feedback breve y motivacional.';

      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 3));

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        _cache[key] = text;
        // Keep cache bounded
        if (_cache.length > 50) {
          _cache.remove(_cache.keys.first);
        }
        return text;
      }
      return null;
    } catch (_) {
      // Timeout, network error, API error - fail silently
      return null;
    }
  }
}
