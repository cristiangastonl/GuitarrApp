# 🎵 Configuración de Spotify Web API

## Configuración Requerida

Para habilitar la funcionalidad de preview de audio, necesitas configurar las credenciales de Spotify Web API.

### 1. Crear App en Spotify Developer Dashboard

1. Ve a [Spotify for Developers](https://developer.spotify.com/dashboard)
2. Inicia sesión con tu cuenta de Spotify
3. Haz clic en "Create App"
4. Completa los campos:
   - **App name**: GuitarrApp
   - **App description**: Guitar learning app with audio previews
   - **Website**: http://localhost (para desarrollo)
   - **Redirect URI**: http://localhost (no se usa para Client Credentials flow)
   - **APIs used**: Web API

### 2. Obtener Credenciales

Después de crear la app:
1. Ve a **Settings** en tu app
2. Copia el **Client ID**
3. Copia el **Client Secret** (haz clic en "Show client secret")

### 3. Configurar en el Código

Edita el archivo `lib/core/services/spotify_service.dart`:

```dart
static const String _clientId = 'TU_CLIENT_ID_AQUI';
static const String _clientSecret = 'TU_CLIENT_SECRET_AQUI';
```

**⚠️ IMPORTANTE: SEGURIDAD**
- Nunca commitees las credenciales al repositorio
- En producción, usa variables de entorno
- El Client Credentials flow solo permite acceso público (búsqueda, previews)

### 4. Funcionalidad Disponible

Con esta configuración podrás:
- ✅ Buscar canciones por artista y título
- ✅ Obtener preview clips de 30 segundos
- ✅ Acceder a metadatos de canciones (duración, imagen de álbum)
- ✅ URLs directas a Spotify

### 5. Limitaciones

- Solo previews de 30 segundos (gratuito)
- No requiere que el usuario tenga Spotify Premium
- No requiere autenticación del usuario
- Rate limits: ~100 requests por minuto

### 6. Formato de Respuesta

El servicio devuelve objetos `SpotifyTrackPreview` con:
```dart
SpotifyTrackPreview(
  id: 'track_id',
  name: 'Song Name',
  artist: 'Artist Name',
  previewUrl: 'https://p.scdn.co/mp3-preview/...',  // 30s clip
  durationMs: 240000,
  albumImageUrl: 'https://i.scdn.co/image/...',
  spotifyUrl: 'https://open.spotify.com/track/...',
)
```

### 7. Fallback

Si no hay preview disponible:
- `previewUrl` será `null`
- La app mostrará "No preview available"
- El botón de play se deshabilitará

---

## ⚡ Inicio Rápido

1. Crea tu app en Spotify Developer Dashboard
2. Copia Client ID y Client Secret
3. Pégalos en `spotify_service.dart`
4. ¡Listo! Los controles de audio funcionarán automáticamente

## 🎸 Experiencia del Usuario

- Cada `RiffGlassCard` tendrá un botón de play/pause
- Previews de 30 segundos de las canciones originales
- Progreso visual durante la reproducción
- Integración perfecta con el diseño glassmórfico existente