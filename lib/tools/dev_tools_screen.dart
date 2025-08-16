import 'package:flutter/material.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/theme/colors.dart';
import '../shared/theme/typography.dart';
import 'icon_generator.dart';

/// Development tools screen for generating assets and testing
class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  bool _isGeneratingIcons = false;
  String _generationStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛠️ Dev Tools'),
        backgroundColor: GuitarrColors.backgroundPrimary,
      ),
      backgroundColor: GuitarrColors.backgroundPrimary,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Development Tools',
              style: GuitarrTypography.headlineLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Herramientas para generar assets y probar componentes',
              style: GuitarrTypography.bodyMedium.copyWith(
                color: GuitarrColors.textTertiary,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Icon Generation Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GuitarrColors.ampOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.app_settings_alt,
                          color: GuitarrColors.ampOrange,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'App Icon Generator',
                        style: GuitarrTypography.titleLarge,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Genera iconos profesionales para iOS y Android manteniendo el design system glassmórfico.',
                    style: GuitarrTypography.bodyMedium,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Icon Preview
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Vista Previa del Icono',
                          style: GuitarrTypography.titleMedium,
                        ),
                        SizedBox(height: 12),
                        IconPreview(size: 120),
                        SizedBox(height: 8),
                        Text(
                          '120x120 (iPhone @3x)',
                          style: GuitarrTypography.labelSmall.copyWith(
                            color: GuitarrColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Generation Controls
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingIcons ? null : _generateIcons,
                          icon: _isGeneratingIcons 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GuitarrColors.textPrimary,
                                  ),
                                )
                              : Icon(Icons.download),
                          label: Text(_isGeneratingIcons 
                              ? 'Generando...' 
                              : 'Generar Todos los Iconos'),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_generationStatus.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _generationStatus.contains('Error')
                            ? GuitarrColors.error.withOpacity(0.1)
                            : GuitarrColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _generationStatus.contains('Error')
                              ? GuitarrColors.error.withOpacity(0.3)
                              : GuitarrColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _generationStatus,
                        style: GuitarrTypography.bodySmall.copyWith(
                          color: _generationStatus.contains('Error')
                              ? GuitarrColors.error
                              : GuitarrColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Icon Specifications
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: GuitarrColors.guitarTeal,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Especificaciones del Icono',
                        style: GuitarrTypography.titleMedium,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildSpecSection('iOS', [
                    '1024x1024 - App Store',
                    '180x180 - iPhone @3x',
                    '120x120 - iPhone @2x',
                    '167x167 - iPad Pro',
                    '152x152 - iPad @2x',
                    '87x87 - Settings @3x',
                    '80x80 - Spotlight @2x',
                    '58x58 - Settings @2x',
                    '60x60 - Notification @3x',
                    '40x40 - Spotlight @1x',
                    '29x29 - Settings @1x',
                    '20x20 - Notification @1x',
                  ]),
                  
                  SizedBox(height: 16),
                  
                  _buildSpecSection('Android', [
                    '512x512 - Play Store',
                    '192x192 - xxxhdpi',
                    '144x144 - xxhdpi', 
                    '96x96 - xhdpi',
                    '72x72 - hdpi',
                    '48x48 - mdpi',
                  ]),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Design System Info
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: GuitarrColors.steelGold,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Design System',
                        style: GuitarrTypography.titleMedium,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildColorSwatch('Amp Orange', GuitarrColors.ampOrange, 'Primary'),
                  _buildColorSwatch('Guitar Teal', GuitarrColors.guitarTeal, 'Secondary'),
                  _buildColorSwatch('Steel Gold', GuitarrColors.steelGold, 'Accent'),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Elementos del Icono:',
                    style: GuitarrTypography.labelLarge,
                  ),
                  SizedBox(height: 8),
                  
                  ...['🎸 Silueta de guitarra eléctrica', 
                      '🌊 Visualización de ondas de audio',
                      '✨ Efectos glassmórficos',
                      '🎯 Acentos de marca en esquinas']
                      .map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              item,
                              style: GuitarrTypography.bodySmall,
                            ),
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecSection(String platform, List<String> specs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          platform,
          style: GuitarrTypography.labelLarge.copyWith(
            color: GuitarrColors.ampOrange,
          ),
        ),
        SizedBox(height: 8),
        ...specs.map((spec) => Padding(
              padding: EdgeInsets.only(left: 16, bottom: 2),
              child: Text(
                '• $spec',
                style: GuitarrTypography.bodySmall,
              ),
            )),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color, String role) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: GuitarrColors.glassBorder,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name ($role)',
              style: GuitarrTypography.bodyMedium,
            ),
          ),
          Text(
            color.value.toRadixString(16).toUpperCase().padLeft(8, '0'),
            style: GuitarrTypography.labelSmall.copyWith(
              color: GuitarrColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateIcons() async {
    setState(() {
      _isGeneratingIcons = true;
      _generationStatus = 'Iniciando generación de iconos...';
    });

    try {
      // Simulate generation process with steps
      setState(() {
        _generationStatus = 'Generando icono base (1024x1024)...';
      });
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _generationStatus = 'Creando variantes para iOS...';
      });
      final iosIcons = await IconGenerator.generateIOSIcons();
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _generationStatus = 'Creando variantes para Android...';
      });
      final androidIcons = await IconGenerator.generateAndroidIcons();
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        _generationStatus = 'Guardando archivos...';
      });
      
      // Save icons to file system for development
      await IconGenerator.saveIconsToFiles();
      
      setState(() {
        _generationStatus = 
            '✅ Iconos generados exitosamente!\n'
            'iOS: ${iosIcons.length} iconos\n'
            'Android: ${androidIcons.length} iconos\n'
            'Guardados en Documents/generated_icons/';
      });

    } catch (e) {
      setState(() {
        _generationStatus = '❌ Error generando iconos: $e';
      });
    } finally {
      setState(() {
        _isGeneratingIcons = false;
      });
    }
  }
}