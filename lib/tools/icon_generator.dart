import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../shared/theme/colors.dart';

/// Professional app icon generator for GuitarrApp
/// Maintains glassmorphic design consistency
class IconGenerator {
  static const double _iconSize = 1024.0;
  
  /// Generate the main app icon with glassmorphic guitar design
  static Future<Uint8List> generateAppIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(_iconSize, _iconSize);
    
    // Background with gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GuitarrColors.backgroundPrimary,
          GuitarrColors.backgroundSecondary,
          GuitarrColors.backgroundTertiary,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Draw background with rounded corners
    final backgroundRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.22), // iOS 22% corner radius
    );
    canvas.drawRRect(backgroundRect, backgroundPaint);
    
    // Glassmorphic overlay
    final glassOverlay = Paint()
      ..color = GuitarrColors.glassOverlay
      ..style = PaintingStyle.fill;
    canvas.drawRRect(backgroundRect, glassOverlay);
    
    // Main guitar silhouette
    _drawGuitarSilhouette(canvas, size);
    
    // Audio waveform visualization
    _drawAudioWaveform(canvas, size);
    
    // Brand accent elements
    _drawBrandAccents(canvas, size);
    
    // Glassmorphic highlight
    _drawGlassHighlight(canvas, size);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(_iconSize.toInt(), _iconSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  /// Draw stylized guitar silhouette
  static void _drawGuitarSilhouette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final guitarScale = size.width * 0.35;
    
    // Guitar body (simplified electric guitar shape)
    final guitarPaint = Paint()
      ..color = GuitarrColors.ampOrange
      ..style = PaintingStyle.fill;
    
    final guitarPath = Path();
    
    // Body (rounded rectangle with curves)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + Offset(0, guitarScale * 0.1),
        width: guitarScale * 0.8,
        height: guitarScale * 1.2,
      ),
      Radius.circular(guitarScale * 0.2),
    );
    guitarPath.addRRect(bodyRect);
    
    // Neck
    final neckRect = Rect.fromCenter(
      center: center + Offset(0, -guitarScale * 0.7),
      width: guitarScale * 0.2,
      height: guitarScale * 0.8,
    );
    guitarPath.addRect(neckRect);
    
    canvas.drawPath(guitarPath, guitarPaint);
    
    // Guitar strings
    final stringPaint = Paint()
      ..color = GuitarrColors.textPrimary.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 6; i++) {
      final stringX = center.dx - (guitarScale * 0.15) + (i * guitarScale * 0.06);
      final stringTop = center.dy - guitarScale * 1.1;
      final stringBottom = center.dy + guitarScale * 0.7;
      
      canvas.drawLine(
        Offset(stringX, stringTop),
        Offset(stringX, stringBottom),
        stringPaint,
      );
    }
    
    // Sound hole
    final soundHolePaint = Paint()
      ..color = GuitarrColors.backgroundPrimary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      center + Offset(0, guitarScale * 0.15),
      guitarScale * 0.15,
      soundHolePaint,
    );
  }
  
  /// Draw audio waveform pattern
  static void _drawAudioWaveform(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final waveScale = size.width * 0.15;
    
    final wavePaint = Paint()
      ..color = GuitarrColors.guitarTeal
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Circular waveform around guitar
    final waveCount = 24;
    final radius = size.width * 0.42;
    
    for (int i = 0; i < waveCount; i++) {
      final angle = (i / waveCount) * 2 * math.pi;
      final waveHeight = waveScale * (0.3 + 0.7 * math.sin(angle * 3));
      
      final innerPoint = Offset(
        center.dx + math.cos(angle) * (radius - waveHeight),
        center.dy + math.sin(angle) * (radius - waveHeight),
      );
      
      final outerPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawLine(innerPoint, outerPoint, wavePaint);
    }
  }
  
  /// Draw brand accent elements
  static void _drawBrandAccents(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Amp-style corner indicators
    final accentPaint = Paint()
      ..color = GuitarrColors.steelGold
      ..style = PaintingStyle.fill;
    
    final cornerSize = size.width * 0.06;
    final cornerOffset = size.width * 0.38;
    
    // Top-left corner
    canvas.drawCircle(
      Offset(cornerOffset, cornerOffset),
      cornerSize,
      accentPaint,
    );
    
    // Top-right corner
    canvas.drawCircle(
      Offset(size.width - cornerOffset, cornerOffset),
      cornerSize,
      accentPaint,
    );
    
    // Bottom-left corner
    canvas.drawCircle(
      Offset(cornerOffset, size.height - cornerOffset),
      cornerSize,
      accentPaint,
    );
    
    // Bottom-right corner
    canvas.drawCircle(
      Offset(size.width - cornerOffset, size.height - cornerOffset),
      cornerSize,
      accentPaint,
    );
  }
  
  /// Draw glassmorphic highlight effect
  static void _drawGlassHighlight(Canvas canvas, Size size) {
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.center,
        colors: [
          GuitarrColors.textPrimary.withOpacity(0.3),
          GuitarrColors.textPrimary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.6, size.height * 0.6))
      ..style = PaintingStyle.fill;
    
    final highlightPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, 0)
      ..lineTo(0, size.height * 0.6)
      ..close();
    
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  /// Generate all required icon sizes for iOS
  static Future<Map<String, Uint8List>> generateIOSIcons() async {
    final baseIcon = await generateAppIcon();
    final icons = <String, Uint8List>{};
    
    // iOS App Icon sizes
    final iosSizes = {
      'Icon-20.png': 20,
      'Icon-20@2x.png': 40,
      'Icon-20@3x.png': 60,
      'Icon-29.png': 29,
      'Icon-29@2x.png': 58,
      'Icon-29@3x.png': 87,
      'Icon-40.png': 40,
      'Icon-40@2x.png': 80,
      'Icon-40@3x.png': 120,
      'Icon-60@2x.png': 120,
      'Icon-60@3x.png': 180,
      'Icon-76.png': 76,
      'Icon-76@2x.png': 152,
      'Icon-83.5@2x.png': 167,
      'Icon-1024.png': 1024,
    };
    
    for (final entry in iosSizes.entries) {
      if (entry.value == 1024) {
        icons[entry.key] = baseIcon;
      } else {
        icons[entry.key] = await _resizeIcon(baseIcon, entry.value);
      }
    }
    
    return icons;
  }
  
  /// Generate all required icon sizes for Android
  static Future<Map<String, Uint8List>> generateAndroidIcons() async {
    final baseIcon = await generateAppIcon();
    final icons = <String, Uint8List>{};
    
    // Android icon sizes
    final androidSizes = {
      'ic_launcher.png': 512, // Play Store
      'mipmap-xxxhdpi/ic_launcher.png': 192,
      'mipmap-xxhdpi/ic_launcher.png': 144,
      'mipmap-xhdpi/ic_launcher.png': 96,
      'mipmap-hdpi/ic_launcher.png': 72,
      'mipmap-mdpi/ic_launcher.png': 48,
    };
    
    for (final entry in androidSizes.entries) {
      if (entry.value == 1024) {
        icons[entry.key] = baseIcon;
      } else {
        icons[entry.key] = await _resizeIcon(baseIcon, entry.value);
      }
    }
    
    return icons;
  }
  
  /// Resize icon to specific dimensions
  static Future<Uint8List> _resizeIcon(Uint8List originalIcon, int size) async {
    // Decode original image
    final codec = await ui.instantiateImageCodec(originalIcon);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;
    
    // Create new canvas with target size
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw resized image
    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  /// Save icons to file system (for development/testing)
  static Future<void> saveIconsToFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final iconsDir = Directory('${directory.path}/generated_icons');
      
      if (!iconsDir.existsSync()) {
        iconsDir.createSync(recursive: true);
      }
      
      // Generate and save iOS icons
      final iosIcons = await generateIOSIcons();
      for (final entry in iosIcons.entries) {
        final file = File('${iconsDir.path}/ios_${entry.key}');
        await file.writeAsBytes(entry.value);
      }
      
      // Generate and save Android icons
      final androidIcons = await generateAndroidIcons();
      for (final entry in androidIcons.entries) {
        final fileName = entry.key.replaceAll('/', '_');
        final file = File('${iconsDir.path}/android_$fileName');
        await file.writeAsBytes(entry.value);
      }
      
      print('Icons saved to: ${iconsDir.path}');
      
    } catch (e) {
      print('Error saving icons: $e');
    }
  }
}

/// Widget to preview the generated icon
class IconPreview extends StatelessWidget {
  final double size;
  
  const IconPreview({super.key, this.size = 200.0});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: IconGenerator.generateAppIcon(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: GuitarrColors.shadowMedium,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.22),
              child: Image.memory(
                snapshot.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: GuitarrColors.error,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Icon(
              Icons.error,
              color: GuitarrColors.textPrimary,
              size: size * 0.3,
            ),
          );
        } else {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: GuitarrColors.surface2,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: GuitarrColors.ampOrange,
              ),
            ),
          );
        }
      },
    );
  }
}