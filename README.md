# GuitarrApp 🎸
**Aplicación móvil para aprender guitarra de forma interactiva**

## 🎵 Estado del Proyecto
**Versión Actual:** Sprint 4 Completado ✅  
**Plataforma:** Flutter (iOS/Android/Web)  
**Arquitectura:** Clean Architecture + Riverpod

## 🚀 Sprints Completados

### ✅ Sprint 1: Core Foundation & Web Audio
- Configuración inicial del proyecto Flutter
- Integración de web audio y FlutterSound
- Sistema de metrónomo visual funcional
- Fundación del sistema de audio

### ✅ Sprint 2: Visual Foundation
- **Sistema de tema glassmorphic** completo con GuitarrColors y GuitarrTypography
- **Componentes visuales** (GlassCard, MusicGlassCard, RiffGlassCard)
- **Pantalla Home** con navegación y estilo guitarrista
- **Diseño optimizado** para músicos en entornos de poca luz

### ✅ Sprint 3: Practice Session Core  
- **Pantalla de práctica** interactiva con metrónomo
- **Sistema de BPM** dinámico (40-200 BPM)
- **Indicadores visuales** de compás y tempo
- **Integración de audio** para práctica en tiempo real

### ✅ Sprint 4: Advanced Features & Optimization
- **🎯 Onboarding Flow:** Selección de objetivos, configuración de equipo, evaluación inicial
- **📊 History Screen Advanced:** Gráficos de progreso y sistema de logros
- **🎛️ Tone Preset System:** Recomendaciones de equipo y presets por género
- **⚡ Performance Optimization:** Gestión de memoria, caché LRU, widgets optimizados
- **🧪 Testing & Quality Assurance:** Suite de tests unitarios y de widgets

## 🏗️ Arquitectura Técnica

### 📁 Estructura del Proyecto
```
lib/
├── core/
│   ├── app/              # Configuración principal
│   ├── cache/            # Sistema de caché LRU con TTL
│   └── services/         # Servicios de audio y Spotify
├── features/
│   ├── home/            # Pantalla principal
│   ├── practice/        # Sistema de práctica
│   ├── onboarding/      # Flujo de bienvenida
│   └── history/         # Historial y progreso
└── shared/
    ├── theme/           # Sistema de tema glassmorphic
    └── widgets/         # Componentes reutilizables
```

### 🎨 Sistema de Diseño
- **Tema:** Glassmorphic oscuro optimizado para músicos
- **Colores:** Paleta guitarrista (amp orange, guitar teal, steel gold)
- **Tipografía:** Especializada para BPM, timers y técnicas
- **Componentes:** Cards con efecto cristal y blur

### 🔧 Tecnologías Clave
- **Flutter 3.x** con arquitectura limpia
- **Riverpod** para gestión de estado reactivo
- **SQLite + SQLCipher** para persistencia segura
- **FlutterSound + Web Audio** para procesamiento de audio
- **LRU Cache** para optimización de rendimiento

## 🎯 Funcionalidades Implementadas

### 🎵 Sistema de Audio
- Metrónomo visual con indicadores de compás
- Control preciso de BPM (40-200)
- Audio web para práctica en tiempo real
- Integración con FlutterSound

### 🎨 Interfaz Glassmorphic
- Cards con efectos de cristal y blur
- Colores adaptivos por género musical
- Optimizado para entornos de poca luz
- Animaciones fluidas y responsivas

### 🎛️ Presets de Sonido
- Sistema de recomendaciones por género
- Matching de equipos (guitarras/amplificadores)
- Cache inteligente para acceso rápido
- Widgets optimizados con lazy loading

### 📊 Seguimiento de Progreso
- Historial de sesiones de práctica
- Sistema de logros y badges
- Gráficos de progreso temporal
- Métricas de rendimiento

### ⚡ Optimización de Rendimiento
- **AppCacheManager:** Cache LRU con TTL automático
- **RepaintBoundary:** Optimización de render
- **Lazy Loading:** Carga diferida de presets
- **Memory Management:** Limpieza automática de recursos

## 🧪 Testing

### 📋 Cobertura de Tests
- **Cache Manager:** Tests unitarios completos para LRU y TTL
- **Theme System:** Validación de colores y tipografía
- **Glass Components:** Tests de widgets glassmorphic
- **Integration Tests:** Flujo completo de la aplicación

### 🎯 Archivos de Test
```
test/
├── unit/
│   ├── cache_test.dart      # Tests del sistema de caché
│   └── theme_test.dart      # Tests del sistema de tema
└── widget/
    └── glass_card_test.dart # Tests de componentes glassmorphic
```

## 🚀 Cómo Ejecutar

### 📱 Desarrollo Local
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Chrome (recomendado para desarrollo)
flutter run -d chrome

# Ejecutar en dispositivo móvil
flutter run
```

### 🧪 Ejecutar Tests
```bash
# Tests unitarios
flutter test test/unit/

# Tests de widgets
flutter test test/widget/

# Todos los tests
flutter test
```

## 🔮 Próximos Pasos

### 🎯 Sprint 5 (Planificado)
- **Integración con Spotify:** Importación de tracks favoritos
- **Social Features:** Compartir progreso y competir
- **Advanced Analytics:** Métricas detalladas de práctica
- **Cloud Sync:** Sincronización entre dispositivos

### 🎸 Funcionalidades Avanzadas
- **Reconocimiento de acordes** con machine learning
- **Tablatura interactiva** sincronizada con audio
- **Jam sessions virtuales** multijugador
- **Integración con DAW** para grabación

## 🤝 Contribuir

Este proyecto está en desarrollo activo. Para contribuir:
1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit con mensaje descriptivo
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

---

**Desarrollado con ❤️ para la comunidad guitarrista**  
*GuitarrApp - Aprende tocando, no solo mirando* 🎸
