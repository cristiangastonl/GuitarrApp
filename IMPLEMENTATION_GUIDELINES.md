# 🎸 GuitarrApp - Implementation Guidelines
*Guía técnica para desarrollo consistente | Agosto 2025*

---

## 🎨 **REGLA DE ORO: Design System Consistency**

### **MANTENER 100% EL LOOK & FEEL GLASSMÓRFICO**

#### **❌ PROHIBIDO:**
- Cambiar colores establecidos
- Crear nuevos sistemas de styling
- Modificar efectos de blur/transparencia
- Alterar borderRadius o spacing
- Introducir nuevas tipografías

#### **✅ OBLIGATORIO:**
- Usar `GuitarrColors.*` para todos los colores
- Extender `GlassCard` para nuevos componentes
- Mantener `borderRadius: 20` consistente
- Seguir spacing múltiplos de 4 (8, 16, 20, 24)
- Usar `GuitarrTypography.*` para textos

---

## 🏗️ **Architecture Guidelines**

### **Project Structure Pattern**
```
lib/features/new_feature/
├── data/
│   ├── repositories/
│   │   └── new_feature_repository.dart
│   └── datasources/
│       ├── local_datasource.dart
│       └── remote_datasource.dart
├── domain/
│   ├── entities/
│   │   └── new_feature.dart
│   ├── repositories/
│   │   └── new_feature_repository.dart
│   └── usecases/
│       └── get_new_feature.dart
└── presentation/
    ├── providers/
    │   └── new_feature_provider.dart
    ├── screens/
    │   └── new_feature_screen.dart
    └── widgets/
        ├── new_feature_card.dart (extends GlassCard)
        └── new_feature_controls.dart
```

### **Service Layer Pattern**
```dart
// ✅ CORRECTO: Extender servicios existentes
class NewFeatureService {
  static const String _logContext = 'NewFeatureService';
  
  // Usar inyección de dependencias
  final DatabaseHelper _database;
  final SecureLoggingService _logger;
  
  NewFeatureService({
    DatabaseHelper? database,
    SecureLoggingService? logger,
  }) : _database = database ?? DatabaseHelper.instance,
       _logger = logger ?? SecureLoggingService.instance;
  
  Future<Result<NewFeature>> getFeature(String id) async {
    try {
      // Validar input
      final validatedId = InputValidationService.validateId(id);
      if (validatedId == null) {
        return Result.error('Invalid ID');
      }
      
      // Usar cache si disponible
      final cached = AppCacheManager.instance.get('feature_$id');
      if (cached != null) {
        return Result.success(NewFeature.fromJson(cached));
      }
      
      // Obtener de database
      final data = await _database.getFeature(validatedId);
      
      // Cache resultado
      AppCacheManager.instance.set('feature_$id', data.toJson());
      
      _logger.logInfo('Feature retrieved successfully', _logContext);
      return Result.success(data);
      
    } catch (e, stackTrace) {
      _logger.logError('Failed to get feature', e, stackTrace, _logContext);
      return Result.error('Failed to get feature: ${e.toString()}');
    }
  }
}

// Provider pattern con Riverpod
final newFeatureServiceProvider = Provider<NewFeatureService>(
  (ref) => NewFeatureService(),
);

final newFeatureProvider = FutureProvider.family<NewFeature, String>(
  (ref, id) async {
    final service = ref.read(newFeatureServiceProvider);
    final result = await service.getFeature(id);
    return result.fold(
      onSuccess: (feature) => feature,
      onError: (error) => throw Exception(error),
    );
  },
);
```

---

## 🎨 **UI Component Patterns**

### **1. GlassCard Extensions**
```dart
// ✅ CORRECTO: Extender GlassCard base
class NewFeatureCard extends GlassCard {
  final NewFeature feature;
  final VoidCallback? onTap;
  
  const NewFeatureCard({
    super.key,
    required this.feature,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      backgroundColor: GuitarrColors.glassOverlay, // ✅ Usar colores establecidos
      borderColor: GuitarrColors.glassBorder,
      borderRadius: 20, // ✅ Mantener consistencia
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GuitarrColors.ampOrange, // ✅ Usar gradient establecido
                      GuitarrColors.ampOrangeDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16), // ✅ Consistent borders
                ),
                child: Icon(
                  feature.icon,
                  color: GuitarrColors.textPrimary,
                  size: 24,
                ),
              ),
              SizedBox(width: 16), // ✅ Spacing múltiplo de 4
              Expanded(
                child: Text(
                  feature.name,
                  style: GuitarrTypography.titleMedium, // ✅ Usar typography establecida
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Content
          Text(
            feature.description,
            style: GuitarrTypography.bodyMedium.copyWith(
              color: GuitarrColors.textSecondary, // ✅ Usar semantic colors
            ),
          ),
          
          // Action button siguiendo el theme
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: Text('Explore Feature'),
            ),
          ),
        ],
      ),
    );
  }
}

// ❌ INCORRECTO: Crear desde cero
class BadNewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800], // ❌ NO usar colores custom
        borderRadius: BorderRadius.circular(15), // ❌ NO cambiar borders
      ),
      child: // ...
    );
  }
}
```

### **2. Custom Painters con Theme Colors**
```dart
// ✅ CORRECTO: Custom painter usando color system
class FeatureVisualizationPainter extends CustomPainter {
  final List<double> data;
  final Animation<double> animation;
  
  FeatureVisualizationPainter({
    required this.data,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Usar colores del theme
    final primaryPaint = Paint()
      ..color = GuitarrColors.ampOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final secondaryPaint = Paint()
      ..color = GuitarrColors.guitarTeal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final backgroundPaint = Paint()
      ..color = GuitarrColors.glassOverlay
      ..style = PaintingStyle.fill;
    
    // Dibujar background glassmórfico
    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundRRect = RRect.fromRectAndRadius(
      backgroundRect,
      Radius.circular(20), // ✅ Consistent border radius
    );
    canvas.drawRRect(backgroundRRect, backgroundPaint);
    
    // Dibujar data visualization
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i] * size.height * animation.value);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, primaryPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget usando el painter
class FeatureVisualizationWidget extends StatefulWidget {
  final List<double> data;
  
  const FeatureVisualizationWidget({super.key, required this.data});
  
  @override
  State<FeatureVisualizationWidget> createState() => _FeatureVisualizationWidgetState();
}

class _FeatureVisualizationWidgetState extends State<FeatureVisualizationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500), // ✅ Smooth animation timing
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic, // ✅ Consistent animation curves
    );
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feature Visualization', 
               style: GuitarrTypography.titleMedium),
          
          SizedBox(height: 16),
          
          Container(
            height: 200,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: FeatureVisualizationPainter(
                    data: widget.data,
                    animation: _animation,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 🔒 **Security & Performance Guidelines**

### **1. Security Patterns**
```dart
// ✅ CORRECTO: Usar servicios de seguridad existentes
class NewFeatureSecureService {
  static const String _logContext = 'NewFeatureSecureService';
  
  Future<Result<String>> processUserInput(String userInput) async {
    try {
      // 1. Validar input
      final sanitizedInput = InputValidationService.sanitizeInput(userInput);
      if (sanitizedInput == null) {
        SecureLoggingService.logWarning(
          'Invalid user input rejected',
          _logContext,
        );
        return Result.error('Invalid input');
      }
      
      // 2. Procesar de forma segura
      final result = await _processSecurely(sanitizedInput);
      
      // 3. Log sin datos sensibles
      SecureLoggingService.logInfo(
        'User input processed successfully',
        _logContext,
      );
      
      return Result.success(result);
      
    } catch (e, stackTrace) {
      // 4. Log error sin exponer datos
      SecureLoggingService.logError(
        'Failed to process user input',
        e,
        stackTrace,
        _logContext,
      );
      return Result.error('Processing failed');
    }
  }
  
  Future<void> storeCredential(String key, String credential) async {
    // ✅ Usar secure storage
    await SecureCredentialsService.storeCredential(key, credential);
  }
  
  Future<String?> getCredential(String key) async {
    // ✅ Usar secure storage
    return await SecureCredentialsService.getCredential(key);
  }
}
```

### **2. Performance Patterns**
```dart
// ✅ CORRECTO: Optimización de memoria y performance
class OptimizedNewFeatureWidget extends StatefulWidget {
  final String featureId;
  
  const OptimizedNewFeatureWidget({super.key, required this.featureId});
  
  @override
  State<OptimizedNewFeatureWidget> createState() => _OptimizedNewFeatureWidgetState();
}

class _OptimizedNewFeatureWidgetState extends State<OptimizedNewFeatureWidget> {
  Timer? _cleanupTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar cleanup automático
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupResources();
    });
    
    // Monitor performance
    PerformanceMonitor.instance.startMonitoring('new_feature_widget');
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // ✅ Optimizar repaints
      child: MemoryOptimizedAudioWidget( // ✅ Usar widgets optimizados existentes
        onMemoryWarning: _handleMemoryWarning,
        child: GlassCard(
          child: Consumer(
            builder: (context, ref, child) {
              final feature = ref.watch(featureProvider(widget.featureId));
              
              return feature.when(
                data: (data) => _buildFeatureContent(data),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureContent(NewFeature feature) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Usar lazy loading para componentes pesados
        if (feature.hasHeavyContent)
          FutureBuilder(
            future: _loadHeavyContent(feature.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return HeavyContentWidget(data: snapshot.data);
              }
              return CircularProgressIndicator();
            },
          )
        else
          LightContentWidget(feature: feature),
      ],
    );
  }
  
  void _cleanupResources() {
    // Limpiar cache antiguo
    AppCacheManager.instance.cleanup();
    
    // Limpiar audio buffers si existen
    // AudioBufferManager.cleanup();
  }
  
  void _handleMemoryWarning() {
    setState(() {
      // Reducir calidad o liberar recursos
    });
  }
  
  @override
  void dispose() {
    _cleanupTimer?.cancel();
    PerformanceMonitor.instance.stopMonitoring('new_feature_widget');
    super.dispose();
  }
}
```

---

## 🧪 **Testing Guidelines**

### **1. Unit Testing Pattern**
```dart
// test/core/services/new_feature_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([DatabaseHelper, SecureLoggingService])
import 'new_feature_service_test.mocks.dart';

void main() {
  group('NewFeatureService', () {
    late NewFeatureService service;
    late MockDatabaseHelper mockDatabase;
    late MockSecureLoggingService mockLogger;
    
    setUp(() {
      mockDatabase = MockDatabaseHelper();
      mockLogger = MockSecureLoggingService();
      service = NewFeatureService(
        database: mockDatabase,
        logger: mockLogger,
      );
    });
    
    group('getFeature', () {
      test('should return feature when database returns valid data', () async {
        // Arrange
        const featureId = 'test_feature_1';
        final expectedFeature = NewFeature(
          id: featureId,
          name: 'Test Feature',
          description: 'Test Description',
        );
        
        when(mockDatabase.getFeature(featureId))
            .thenAnswer((_) async => expectedFeature);
        
        // Act
        final result = await service.getFeature(featureId);
        
        // Assert
        expect(result.isSuccess, true);
        expect(result.data, equals(expectedFeature));
        verify(mockDatabase.getFeature(featureId)).called(1);
        verify(mockLogger.logInfo(any, any)).called(1);
      });
      
      test('should return error when input validation fails', () async {
        // Arrange
        const invalidId = '';
        
        // Act
        final result = await service.getFeature(invalidId);
        
        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Invalid ID'));
        verifyNever(mockDatabase.getFeature(any));
      });
      
      test('should handle database exceptions gracefully', () async {
        // Arrange
        const featureId = 'test_feature_1';
        final exception = Exception('Database connection failed');
        
        when(mockDatabase.getFeature(featureId))
            .thenThrow(exception);
        
        // Act
        final result = await service.getFeature(featureId);
        
        // Assert
        expect(result.isError, true);
        expect(result.error, contains('Failed to get feature'));
        verify(mockLogger.logError(any, exception, any, any)).called(1);
      });
    });
  });
}
```

### **2. Widget Testing Pattern**
```dart
// test/features/new_feature/presentation/widgets/new_feature_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('NewFeatureCard', () {
    late NewFeature testFeature;
    
    setUp(() {
      testFeature = NewFeature(
        id: 'test_1',
        name: 'Test Feature',
        description: 'This is a test feature',
        icon: Icons.star,
      );
    });
    
    testWidgets('should display feature information correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme, // ✅ Usar theme consistente
            home: Scaffold(
              body: NewFeatureCard(feature: testFeature),
            ),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.text('Test Feature'), findsOneWidget);
      expect(find.text('This is a test feature'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
    
    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool wasTapped = false;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: NewFeatureCard(
                feature: testFeature,
                onTap: () => wasTapped = true,
              ),
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(NewFeatureCard));
      
      // Assert
      expect(wasTapped, true);
    });
    
    testWidgets('should use glassmorphic styling', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: NewFeatureCard(feature: testFeature),
            ),
          ),
        ),
      );
      
      // Act & Assert - Verificar que usa GlassCard
      expect(find.byType(GlassCard), findsOneWidget);
      
      // Verificar colores del theme
      final glassCard = tester.widget<GlassCard>(find.byType(GlassCard));
      expect(glassCard.backgroundColor, GuitarrColors.glassOverlay);
      expect(glassCard.borderColor, GuitarrColors.glassBorder);
      expect(glassCard.borderRadius, 20);
    });
  });
}
```

### **3. Integration Testing Pattern**
```dart
// integration_test/new_feature_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('New Feature Flow Integration Tests', () {
    testWidgets('complete new feature user flow', (tester) async {
      // Arrange - Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Act & Assert - Navigate to new feature
      expect(find.text('GuitarrApp'), findsOneWidget);
      
      // Tap on new feature
      await tester.tap(find.text('New Feature'));
      await tester.pumpAndSettle();
      
      // Verify new feature screen loads
      expect(find.byType(NewFeatureScreen), findsOneWidget);
      
      // Test feature interaction
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(Duration(seconds: 2));
      
      // Verify result
      expect(find.text('Feature Activated'), findsOneWidget);
      
      // Test navigation back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Verify back to home
      expect(find.text('GuitarrApp'), findsOneWidget);
    });
    
    testWidgets('new feature error handling', (tester) async {
      // Test error scenarios
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Force an error condition (e.g., no network)
      // Test error UI displays correctly
      // Test retry functionality
      // Test graceful degradation
    });
  });
}
```

---

## 📊 **Analytics & Monitoring Guidelines**

### **1. Event Tracking Pattern**
```dart
// ✅ CORRECTO: Tracking consistente
class NewFeatureAnalytics {
  static const String _featureContext = 'new_feature';
  
  static Future<void> trackFeatureViewed(String featureId) async {
    await AnalyticsService.trackFeatureUsage('${_featureContext}_viewed');
    
    // Parámetros adicionales específicos
    await FirebaseAnalytics.instance.logEvent(
      name: 'feature_interaction',
      parameters: {
        'feature_type': _featureContext,
        'action': 'viewed',
        'feature_id': featureId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  static Future<void> trackFeatureUsed({
    required String featureId,
    required String action,
    Map<String, dynamic>? customParameters,
  }) async {
    await AnalyticsService.trackFeatureUsage('${_featureContext}_$action');
    
    final parameters = {
      'feature_type': _featureContext,
      'action': action,
      'feature_id': featureId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?customParameters,
    };
    
    await FirebaseAnalytics.instance.logEvent(
      name: 'feature_interaction',
      parameters: parameters,
    );
  }
  
  static Future<void> trackFeatureError({
    required String featureId,
    required String errorType,
    String? errorMessage,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'feature_error',
      parameters: {
        'feature_type': _featureContext,
        'feature_id': featureId,
        'error_type': errorType,
        'error_message': errorMessage?.substring(0, 100), // Limitar longitud
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    // También log para debugging (sin datos sensibles)
    SecureLoggingService.logError(
      'Feature error: $errorType',
      Exception(errorMessage),
      StackTrace.current,
      _featureContext,
    );
  }
}

// Uso en widgets
class NewFeatureScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends ConsumerState<NewFeatureScreen> {
  @override
  void initState() {
    super.initState();
    
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NewFeatureAnalytics.trackFeatureViewed(widget.featureId);
    });
  }
  
  void _onFeatureButtonPressed() async {
    try {
      // Track interaction
      await NewFeatureAnalytics.trackFeatureUsed(
        featureId: widget.featureId,
        action: 'button_pressed',
        customParameters: {
          'button_type': 'primary_action',
        },
      );
      
      // Execute feature logic
      await _executeFeature();
      
    } catch (e) {
      // Track error
      await NewFeatureAnalytics.trackFeatureError(
        featureId: widget.featureId,
        errorType: 'execution_failed',
        errorMessage: e.toString(),
      );
      
      // Show user-friendly error
      _showErrorDialog();
    }
  }
}
```

---

## 🚀 **Performance Guidelines**

### **1. Memory Management**
```dart
// ✅ CORRECTO: Gestión de memoria optimizada
class OptimizedNewFeatureService {
  static const int _maxCacheSize = 50;
  static const Duration _cacheTimeout = Duration(minutes: 15);
  
  final LRUMap<String, CachedFeature> _cache = LRUMap(_maxCacheSize);
  Timer? _cleanupTimer;
  
  OptimizedNewFeatureService() {
    _setupPeriodicCleanup();
  }
  
  void _setupPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupExpiredCache();
    });
  }
  
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cache.forEach((key, cached) {
      if (now.difference(cached.timestamp) > _cacheTimeout) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    // Log cleanup stats
    SecureLoggingService.logInfo(
      'Cache cleanup: removed ${expiredKeys.length} expired items',
      'OptimizedNewFeatureService',
    );
  }
  
  Future<NewFeature?> getFeature(String id) async {
    // Check cache first
    final cached = _cache[id];
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < _cacheTimeout) {
      return cached.feature;
    }
    
    // Load from database
    final feature = await _loadFeatureFromDatabase(id);
    if (feature != null) {
      _cache[id] = CachedFeature(
        feature: feature,
        timestamp: DateTime.now(),
      );
    }
    
    return feature;
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class CachedFeature {
  final NewFeature feature;
  final DateTime timestamp;
  
  CachedFeature({required this.feature, required this.timestamp});
}
```

### **2. Audio Performance**
```dart
// ✅ CORRECTO: Optimización de audio
class OptimizedAudioFeatureService {
  static const int _bufferSize = 1024;
  static const Duration _maxRecordingDuration = Duration(minutes: 10);
  
  final List<Float32List> _audioBuffers = [];
  Timer? _memoryCleanupTimer;
  
  Future<void> startAudioProcessing() async {
    // Monitor memory usage
    _memoryCleanupTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkMemoryUsage();
    });
    
    // Configure audio settings for optimal performance
    await _configureAudioSession();
  }
  
  void _checkMemoryUsage() {
    final memoryUsage = PerformanceMonitor.instance.getMemoryUsage();
    
    if (memoryUsage > 200 * 1024 * 1024) { // 200MB threshold
      _freeOldAudioBuffers();
      
      SecureLoggingService.logWarning(
        'High memory usage detected, cleaning audio buffers',
        'OptimizedAudioFeatureService',
      );
    }
  }
  
  void _freeOldAudioBuffers() {
    // Keep only the last 10 seconds of audio
    const maxBuffers = 10 * 44100 ~/ _bufferSize; // 10 seconds at 44.1kHz
    
    if (_audioBuffers.length > maxBuffers) {
      final buffersToRemove = _audioBuffers.length - maxBuffers;
      _audioBuffers.removeRange(0, buffersToRemove);
    }
  }
  
  Future<void> processAudioBuffer(Float32List buffer) async {
    // Process in background isolate for heavy computation
    final processed = await compute(_processAudioInIsolate, buffer);
    
    // Store only if within limits
    if (_audioBuffers.length < 100) { // Max 100 buffers
      _audioBuffers.add(processed);
    }
  }
  
  static Float32List _processAudioInIsolate(Float32List buffer) {
    // Heavy audio processing here
    // This runs in a separate isolate to avoid blocking UI
    return buffer; // Processed buffer
  }
  
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _audioBuffers.clear();
  }
}
```

---

## 📱 **Platform Guidelines**

### **1. iOS Specific**
```dart
// ios/Runner/Info.plist additions
/*
<key>NSMicrophoneUsageDescription</key>
<string>GuitarrApp needs microphone access to analyze your guitar playing and provide feedback</string>

<key>NSCameraUsageDescription</key>  
<string>GuitarrApp can use your camera to scan guitar tablatures</string>

<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>
*/

// Platform-specific optimizations
class iOSSpecificOptimizations {
  static Future<void> configureAudioSession() async {
    if (Platform.isIOS) {
      // Configure AVAudioSession for optimal guitar recording
      await FlutterSound().startSession(
        category: SessionCategory.playAndRecord,
        mode: SessionMode.measurement,
        options: [
          SessionOption.defaultToSpeaker,
          SessionOption.allowBluetooth,
        ],
      );
    }
  }
  
  static void optimizeForBatteryLife() {
    if (Platform.isIOS) {
      // Reduce frame rate when app is not active
      WidgetsBinding.instance.addObserver(
        _AppLifecycleObserver(),
      );
    }
  }
}
```

### **2. Android Specific**
```dart
// android/app/src/main/AndroidManifest.xml additions
/*
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Network security config -->
<application
    android:networkSecurityConfig="@xml/network_security_config"
    android:usesCleartextTraffic="false">
*/

// android/app/src/main/res/xml/network_security_config.xml
/*
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">guitarrapp.com</domain>
    </domain-config>
</network-security-config>
*/

class AndroidSpecificOptimizations {
  static Future<void> configureAudioOptimizations() async {
    if (Platform.isAndroid) {
      // Configure for low-latency audio
      await MethodChannel('audio_optimization').invokeMethod('setLowLatency');
    }
  }
  
  static void handlePermissions() async {
    if (Platform.isAndroid) {
      // Request permissions with proper rationale
      final status = await Permission.microphone.request();
      
      if (status.isDenied) {
        // Show custom dialog explaining why permission is needed
        _showPermissionRationaleDialog();
      }
    }
  }
}
```

---

## 🎯 **Quick Reference Checklist**

### **Before Creating New Components:**
- [ ] ¿Puedo extender `GlassCard` en lugar de crear desde cero?
- [ ] ¿Estoy usando `GuitarrColors.*` para todos los colores?
- [ ] ¿Mantengo `borderRadius: 20` consistente?
- [ ] ¿Uso `GuitarrTypography.*` para textos?
- [ ] ¿Sigo spacing múltiplos de 4?

### **Before Adding Services:**
- [ ] ¿Extiendo patrones existentes en lugar de reinventar?
- [ ] ¿Uso `SecureLoggingService` para logs?
- [ ] ¿Valido inputs con `InputValidationService`?
- [ ] ¿Manejo errores gracefully?
- [ ] ¿Implemento caching apropiado?

### **Before Pushing Code:**
- [ ] ¿Escribí tests unitarios?
- [ ] ¿Agregué analytics tracking?
- [ ] ¿Documenté APIs públicas?
- [ ] ¿Performance está optimizado?
- [ ] ¿Security está validado?

### **Emergency Debugging:**
```dart
// Debug colors - remover antes de production
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.red, width: 2), // DEBUG ONLY
  ),
  child: widget,
)

// Debug logs - usar SecureLoggingService en production
print('DEBUG: $data'); // ❌ NO en production
SecureLoggingService.logDebug('Debug info', 'Context'); // ✅ CORRECTO
```

Este documento debe ser la referencia principal para cualquier desarrollo nuevo en GuitarrApp. Mantener la consistencia es clave para el éxito del proyecto.