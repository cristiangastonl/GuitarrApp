import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback_analysis_service.dart';
import 'backing_track_service.dart';

/// A contextual tip for improving guitar practice
class PracticeTip {
  final String id;
  final TipCategory category;
  final TipPriority priority;
  final String title;
  final String description;
  final String actionable;
  final String? iconName;
  final List<String> keywords;
  
  const PracticeTip({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionable,
    this.iconName,
    this.keywords = const [],
  });
  
  /// Get appropriate color for the tip based on priority
  TipColor get color {
    switch (priority) {
      case TipPriority.critical:
        return TipColor.red;
      case TipPriority.important:
        return TipColor.orange;
      case TipPriority.helpful:
        return TipColor.blue;
      case TipPriority.motivational:
        return TipColor.green;
    }
  }
}

/// Categories of practice tips
enum TipCategory {
  timing,
  technique,
  equipment,
  practice,
  motivation;
  
  String get displayName {
    switch (this) {
      case TipCategory.timing:
        return 'Timing';
      case TipCategory.technique:
        return 'Técnica';
      case TipCategory.equipment:
        return 'Equipamiento';
      case TipCategory.practice:
        return 'Práctica';
      case TipCategory.motivation:
        return 'Motivación';
    }
  }
  
  String get icon {
    switch (this) {
      case TipCategory.timing:
        return '⏱️';
      case TipCategory.technique:
        return '🎸';
      case TipCategory.equipment:
        return '🎛️';
      case TipCategory.practice:
        return '📚';
      case TipCategory.motivation:
        return '🔥';
    }
  }
}

/// Priority levels for tips
enum TipPriority {
  critical,    // Must address immediately
  important,   // Should address soon
  helpful,     // Nice to know
  motivational; // Encouragement
  
  String get displayName {
    switch (this) {
      case TipPriority.critical:
        return 'Crítico';
      case TipPriority.important:
        return 'Importante';
      case TipPriority.helpful:
        return 'Útil';
      case TipPriority.motivational:
        return 'Motivacional';
    }
  }
}

/// Color scheme for tips
enum TipColor {
  red,
  orange, 
  blue,
  green;
  
  String get colorName {
    switch (this) {
      case TipColor.red:
        return 'red';
      case TipColor.orange:
        return 'orange';
      case TipColor.blue:
        return 'blue';
      case TipColor.green:
        return 'green';
    }
  }
}

/// Context for generating personalized tips
class TipContext {
  final SessionAnalysis analysis;
  final BackingTrack? currentRiff;
  final SessionHistory history;
  final Map<String, dynamic> overallStats;
  
  const TipContext({
    required this.analysis,
    this.currentRiff,
    required this.history,
    required this.overallStats,
  });
}

/// Service for generating contextual practice tips
class TipsEngineService {
  final Ref _ref;
  
  TipsEngineService(this._ref);
  
  /// Generate personalized tips based on session analysis
  List<PracticeTip> generateTips(TipContext context) {
    final tips = <PracticeTip>[];
    
    // Add timing-related tips
    tips.addAll(_generateTimingTips(context));
    
    // Add technique-specific tips
    tips.addAll(_generateTechniqueTips(context));
    
    // Add equipment suggestions
    tips.addAll(_generateEquipmentTips(context));
    
    // Add practice methodology tips
    tips.addAll(_generatePracticeTips(context));
    
    // Add motivational tips
    tips.addAll(_generateMotivationalTips(context));
    
    // Sort by priority and return top 3
    tips.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    
    return tips.take(3).toList();
  }
  
  /// Generate timing-related tips
  List<PracticeTip> _generateTimingTips(TipContext context) {
    final tips = <PracticeTip>[];
    final analysis = context.analysis;
    
    // Poor timing consistency
    if (analysis.timingScore < 60) {
      tips.add(const PracticeTip(
        id: 'timing_slow_down',
        category: TipCategory.timing,
        priority: TipPriority.critical,
        title: 'Reduce el Tempo',
        description: 'Tu timing está inconsistente. Es mejor tocar lento y correcto que rápido e impreciso.',
        actionable: 'Baja el BPM en 10-20 y enfócate en la precisión antes que en la velocidad.',
        iconName: 'slow_motion_video',
        keywords: ['timing', 'bpm', 'tempo'],
      ));
    }
    
    // Good timing but room for improvement
    if (analysis.timingScore >= 60 && analysis.timingScore < 80) {
      tips.add(const PracticeTip(
        id: 'timing_metronome_focus',
        category: TipCategory.timing,
        priority: TipPriority.important,
        title: 'Practica con el Metrónomo',
        description: 'Tu timing está mejorando. Enfócate en estar perfectamente sincronizado con cada click.',
        actionable: 'Toca solo las notas en los tiempos fuertes hasta dominarlas, luego agrega las otras.',
        iconName: 'timer',
        keywords: ['metronome', 'timing', 'sync'],
      ));
    }
    
    // Excellent timing
    if (analysis.timingScore >= 90) {
      tips.add(const PracticeTip(
        id: 'timing_advanced',
        category: TipCategory.timing,
        priority: TipPriority.helpful,
        title: '¡Timing Excelente!',
        description: 'Tu timing es muy sólido. Considera practicar con subdivisiones más complejas.',
        actionable: 'Intenta acentos en el off-beat o cambia a 16th notes para el próximo desafío.',
        iconName: 'star',
        keywords: ['advanced', 'subdivision', 'complex'],
      ));
    }
    
    return tips;
  }
  
  /// Generate technique-specific tips based on the current riff
  List<PracticeTip> _generateTechniqueTips(TipContext context) {
    final tips = <PracticeTip>[];
    final riff = context.currentRiff;
    
    if (riff == null) return tips;
    
    // Palm muting tips
    if (riff.techniques.contains('palm-muting')) {
      tips.add(const PracticeTip(
        id: 'technique_palm_muting',
        category: TipCategory.technique,
        priority: TipPriority.important,
        title: 'Técnica de Palm Muting',
        description: 'El palm muting requiere el equilibrio perfecto entre presión y liberación.',
        actionable: 'Coloca el lateral de tu mano derecha ligeramente sobre las cuerdas cerca del puente.',
        iconName: 'pan_tool',
        keywords: ['palm-muting', 'muting', 'technique'],
      ));
    }
    
    // Alternate picking tips
    if (riff.techniques.contains('alternate-picking')) {
      tips.add(const PracticeTip(
        id: 'technique_alternate_picking',
        category: TipCategory.technique,
        priority: TipPriority.important,
        title: 'Alternate Picking',
        description: 'La economía de movimiento es clave para el alternate picking eficiente.',
        actionable: 'Alterna DOWN-UP consistentemente, mantén la muñeca relajada y el movimiento pequeño.',
        iconName: 'swap_vert',
        keywords: ['alternate-picking', 'picking', 'efficiency'],
      ));
    }
    
    // Power chords tips
    if (riff.techniques.contains('power-chords')) {
      tips.add(const PracticeTip(
        id: 'technique_power_chords',
        category: TipCategory.technique,
        priority: TipPriority.helpful,
        title: 'Power Chords Limpios',
        description: 'Los power chords suenan mejor cuando evitas las cuerdas que no debes tocar.',
        actionable: 'Usa el dedo índice para mutear las cuerdas superiores que no forman parte del acorde.',
        iconName: 'electric_bolt',
        keywords: ['power-chords', 'muting', 'clean'],
      ));
    }
    
    // Bending tips
    if (riff.techniques.contains('bending')) {
      tips.add(const PracticeTip(
        id: 'technique_bending',
        category: TipCategory.technique,
        priority: TipPriority.important,
        title: 'Bending Preciso',
        description: 'Los bends requieren fuerza y precisión para alcanzar la afinación correcta.',
        actionable: 'Usa múltiples dedos para empujar la cuerda y practica el pitch objetivo sin el bend primero.',
        iconName: 'trending_up',
        keywords: ['bending', 'pitch', 'intonation'],
      ));
    }
    
    return tips;
  }
  
  /// Generate equipment-related tips
  List<PracticeTip> _generateEquipmentTips(TipContext context) {
    final tips = <PracticeTip>[];
    final riff = context.currentRiff;
    
    if (riff == null) return tips;
    
    // Genre-specific equipment suggestions
    switch (riff.genre.toLowerCase()) {
      case 'metal':
        tips.add(const PracticeTip(
          id: 'equipment_metal',
          category: TipCategory.equipment,
          priority: TipPriority.helpful,
          title: 'Configuración para Metal',
          description: 'El metal requiere distorsión alta y graves ajustados para obtener el tone correcto.',
          actionable: 'Sube la ganancia, ajusta graves en 7-8, medios en 5-6, agudos en 6-7.',
          iconName: 'equalizer',
          keywords: ['metal', 'distortion', 'eq'],
        ));
        break;
      
      case 'rock':
        tips.add(const PracticeTip(
          id: 'equipment_rock',
          category: TipCategory.equipment,
          priority: TipPriority.helpful,
          title: 'Tone Clásico de Rock',
          description: 'El rock clásico se beneficia de una distorsión media con medios prominentes.',
          actionable: 'Distorsión media, realza los medios para cortar en la mezcla, agrega un poco de reverb.',
          iconName: 'tune',
          keywords: ['rock', 'classic', 'mids'],
        ));
        break;
      
      case 'grunge':
        tips.add(const PracticeTip(
          id: 'equipment_grunge',
          category: TipCategory.equipment,
          priority: TipPriority.helpful,
          title: 'Sonido Grunge',
          description: 'El grunge combina limpio y distorsionado con un sonido crudo y natural.',
          actionable: 'Alterna entre limpio y distorsión sucia, no uses demasiados efectos.',
          iconName: 'music_note',
          keywords: ['grunge', 'raw', 'dynamics'],
        ));
        break;
    }
    
    return tips;
  }
  
  /// Generate practice methodology tips
  List<PracticeTip> _generatePracticeTips(TipContext context) {
    final tips = <PracticeTip>[];
    final analysis = context.analysis;
    final frequency = analysis.practiceFrequency;
    
    // Low practice frequency
    if (frequency < 3) {
      tips.add(const PracticeTip(
        id: 'practice_frequency',
        category: TipCategory.practice,
        priority: TipPriority.important,
        title: 'Practica Más Seguido',
        description: 'La consistencia es más importante que las sesiones largas.',
        actionable: 'Intenta practicar 15-20 minutos diarios en lugar de sesiones largas ocasionales.',
        iconName: 'event_repeat',
        keywords: ['frequency', 'consistency', 'daily'],
      ));
    }
    
    // Good progress, suggest next steps
    if (analysis.progressScore > 70) {
      tips.add(const PracticeTip(
        id: 'practice_next_level',
        category: TipCategory.practice,
        priority: TipPriority.helpful,
        title: 'Sube el Desafío',
        description: 'Estás progresando bien. Es hora de aumentar la dificultad.',
        actionable: 'Incrementa el BPM objetivo en 5-10 o intenta una variación más compleja del riff.',
        iconName: 'trending_up',
        keywords: ['progress', 'challenge', 'level-up'],
      ));
    }
    
    // Struggling with consistency
    if (analysis.consistencyScore < 60) {
      tips.add(const PracticeTip(
        id: 'practice_consistency',
        category: TipCategory.practice,
        priority: TipPriority.important,
        title: 'Enfócate en la Consistencia',
        description: 'Tu ejecución varía mucho entre sesiones.',
        actionable: 'Practica el mismo segmento repetidamente hasta que salga igual 5 veces seguidas.',
        iconName: 'repeat',
        keywords: ['consistency', 'repetition', 'focus'],
      ));
    }
    
    return tips;
  }
  
  /// Generate motivational tips
  List<PracticeTip> _generateMotivationalTips(TipContext context) {
    final tips = <PracticeTip>[];
    final analysis = context.analysis;
    final overallStats = context.overallStats;
    
    // Celebrate milestones
    final totalSessions = overallStats['totalSessions'] as int;
    if (totalSessions > 0 && totalSessions % 10 == 0) {
      tips.add(PracticeTip(
        id: 'motivation_milestone',
        category: TipCategory.motivation,
        priority: TipPriority.motivational,
        title: '¡$totalSessions Sesiones Completadas!',
        description: 'Has dedicado tiempo real a mejorar tu técnica. ¡Sigue así!',
        actionable: 'Celebra tu progreso y mantén el momentum practicando regularmente.',
        iconName: 'emoji_events',
        keywords: ['milestone', 'achievement', 'progress'],
      ));
    }
    
    // Encourage good performance
    if (analysis.overallScore >= 80) {
      tips.add(const PracticeTip(
        id: 'motivation_great_job',
        category: TipCategory.motivation,
        priority: TipPriority.motivational,
        title: '¡Excelente Sesión!',
        description: 'Tu técnica está mejorando notablemente. El esfuerzo está dando frutos.',
        actionable: 'Mantén este nivel de práctica y considera grabarte tocando la canción completa.',
        iconName: 'star',
        keywords: ['excellent', 'improvement', 'encourage'],
      ));
    }
    
    // Encourage after poor performance
    if (analysis.overallScore < 50) {
      tips.add(const PracticeTip(
        id: 'motivation_keep_going',
        category: TipCategory.motivation,
        priority: TipPriority.motivational,
        title: 'No Te Rindas',
        description: 'Todos los guitarristas pasan por días difíciles. La perseverancia es clave.',
        actionable: 'Toma un descanso si es necesario, luego vuelve con el BPM más lento.',
        iconName: 'favorite',
        keywords: ['persistence', 'encourage', 'support'],
      ));
    }
    
    // Practice streak encouragement
    final longestStreak = overallStats['longestStreak'] as int;
    if (longestStreak >= 7) {
      tips.add(PracticeTip(
        id: 'motivation_streak',
        category: TipCategory.motivation,
        priority: TipPriority.motivational,
        title: '¡Racha de $longestStreak Días!',
        description: 'Tu dedicación constante es impresionante. La disciplina genera resultados.',
        actionable: 'Sigue construyendo este hábito positivo, día a día.',
        iconName: 'local_fire_department',
        keywords: ['streak', 'dedication', 'habit'],
      ));
    }
    
    return tips;
  }
  
  /// Get tip by ID (useful for tracking which tips have been shown)
  PracticeTip? getTipById(String tipId, TipContext context) {
    final allTips = generateTips(context);
    try {
      return allTips.firstWhere((tip) => tip.id == tipId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get tips by category
  List<PracticeTip> getTipsByCategory(TipCategory category, TipContext context) {
    final allTips = generateTips(context);
    return allTips.where((tip) => tip.category == category).toList();
  }
  
  /// Get tips by priority level
  List<PracticeTip> getTipsByPriority(TipPriority priority, TipContext context) {
    final allTips = generateTips(context);
    return allTips.where((tip) => tip.priority == priority).toList();
  }
}

/// Provider for the tips engine service
final tipsEngineServiceProvider = Provider<TipsEngineService>((ref) {
  return TipsEngineService(ref);
});

/// Provider for generating tips based on latest session analysis
final currentSessionTipsProvider = Provider.family<List<PracticeTip>, TipContext>((ref, context) {
  final service = ref.watch(tipsEngineServiceProvider);
  return service.generateTips(context);
});