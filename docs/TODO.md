# TODO - Próximos Pasos

## Prioridad Alta

### Verificación y Testing
- [ ] Ejecutar `flutter pub get` y resolver cualquier error de dependencias
- [ ] Ejecutar `flutter analyze` y corregir warnings
- [ ] Verificar que la app compila en iOS y Android
- [ ] Probar flujo completo: Home → Curso → Ejercicio → Resultados

### Audio Real
- [ ] Verificar que `RealTimeAudioAnalysisService` detecta notas correctamente
- [ ] Calibrar umbrales de detección (`_perfectTimingMs`, `_goodTimingMs`, etc.)
- [ ] Probar metrónomo en dispositivos reales
- [ ] Ajustar latencia de audio si es necesario

### Base de Datos
- [ ] Probar migración de DB en dispositivos con versión anterior
- [ ] Verificar persistencia de progreso entre sesiones

---

## Prioridad Media

### Más Contenido
- [ ] Agregar Curso 3: "Acordes Abiertos"
- [ ] Agregar Curso 4: "Escalas Básicas"
- [ ] Más ejercicios de diagnóstico para mejor evaluación de nivel
- [ ] Ejercicios de técnica (hammer-on, pull-off)

### UX Improvements
- [ ] Animaciones de transición entre pantallas
- [ ] Vibración/haptic feedback en beats
- [ ] Sonido de "correcto/incorrecto" opcional
- [ ] Tutorial de primer uso

### Visualización
- [ ] Visualización de espectro de frecuencias durante práctica
- [ ] Gráfico de progreso histórico
- [ ] Comparación de intentos anteriores

---

## Prioridad Baja (Futuro)

### Fase 6: Integración LLM
- [ ] Crear `LLMService` para llamar a Claude API
- [ ] Almacenar API key de forma segura
- [ ] Generar feedback personalizado basado en patrones de error
- [ ] Fallback a reglas si API no disponible
- [ ] Generar planes de práctica personalizados

### Acordes
- [ ] Ejercicios de cambio de acordes
- [ ] Integrar `ChordRecognitionService` en evaluación
- [ ] Visualización de diagrama de acordes

### Técnicas Avanzadas
- [ ] Ejercicios de hammer-on y pull-off
- [ ] Detección de bends
- [ ] Ejercicios de fingerpicking

### Gamificación
- [ ] Sistema de logros/achievements
- [ ] Racha diaria con recompensas
- [ ] Niveles de usuario con iconos
- [ ] Tabla de clasificación (opcional)

### Social (Opcional)
- [ ] Compartir logros
- [ ] Desafíos entre usuarios
- [ ] Grabaciones públicas

### Plataforma
- [ ] Soporte web completo
- [ ] Sincronización entre dispositivos
- [ ] Modo offline robusto

---

## Bugs Conocidos

- [ ] `glass_card.dart` tiene referencias a widgets eliminados en `RiffGlassCard` - simplificar o eliminar
- [ ] Auth feature referenciada pero no existe - eliminado correctamente

---

## Notas Técnicas

### Latencia de Audio
El sistema actual asume una latencia de ~50ms. Si hay problemas de timing:
1. Ajustar `_perfectTimingMs`, `_goodTimingMs`, `_okTimingMs` en `ExerciseEvaluationService`
2. Considerar compensación de latencia configurable

### Detección de Pitch
Si la detección falla con guitarras acústicas:
1. Revisar `_noiseThreshold` en `RealTimeAudioAnalysisService`
2. Ajustar `sensitivity` en `AudioAnalysisSettings`

### Memoria
Los ejercicios se cargan en memoria desde JSON. Si hay muchos ejercicios:
1. Considerar paginación
2. Cache con expiración
3. Lazy loading de ejercicios

---

## Comandos Útiles

```bash
# Verificar estado
flutter doctor
flutter pub get
flutter analyze

# Ejecutar
flutter run

# Build
flutter build apk
flutter build ios

# Limpiar
flutter clean
flutter pub get
```
