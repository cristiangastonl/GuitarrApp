import 'package:flutter/material.dart';
import '../../core/models/tone_preset.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

/// Optimized preset grid with lazy loading and memory management
class OptimizedPresetGrid extends StatefulWidget {
  final List<TonePreset> presets;
  final Function(TonePreset) onPresetSelected;
  final TonePreset? selectedPreset;
  final bool showRecommendationBadge;
  final bool showCompatibilityBadge;
  final bool allowEdit;

  const OptimizedPresetGrid({
    super.key,
    required this.presets,
    required this.onPresetSelected,
    this.selectedPreset,
    this.showRecommendationBadge = false,
    this.showCompatibilityBadge = false,
    this.allowEdit = false,
  });

  @override
  State<OptimizedPresetGrid> createState() => _OptimizedPresetGridState();
}

class _OptimizedPresetGridState extends State<OptimizedPresetGrid>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  final double _itemExtent = 180.0; // Fixed item height for better performance

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.presets.isEmpty) {
      return _buildEmptyState();
    }

    // Use ListView.builder with custom layout for better performance
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: (widget.presets.length / 2).ceil(),
      itemBuilder: (context, rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, widget.presets.length);
        final rowPresets = widget.presets.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: _buildPresetCard(rowPresets[0])),
              if (rowPresets.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(child: _buildPresetCard(rowPresets[1])),
              ] else
                const Spacer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetCard(TonePreset preset) {
    final isSelected = widget.selectedPreset?.id == preset.id;
    final genreColor = GuitarrColors.getGenreColor(preset.genre);
    
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: MusicGlassCard(
          genre: preset.genre,
          isActive: isSelected,
          onTap: () => widget.onPresetSelected(preset),
          padding: const EdgeInsets.all(16),
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: _itemExtent - 8, // Adjust for padding
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preset name with glassmorphic styling
                    Text(
                      preset.name,
                      style: GuitarrTypography.titleMedium.copyWith(
                        color: GuitarrColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Amp model with secondary text
                    Text(
                      preset.ampModel.replaceAll('_', ' ').toUpperCase(),
                      style: GuitarrTypography.bodySmall.copyWith(
                        color: GuitarrColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Genre badge with glassmorphic styling
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: genreColor.withOpacity(0.15),
                        border: Border.all(
                          color: genreColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        preset.genre.toUpperCase(),
                        style: GuitarrTypography.techniqueTag.copyWith(
                          color: genreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Gain and distortion meters with glassmorphic styling
                    Row(
                      children: [
                        _buildMeterIndicator('GAIN', preset.gain),
                        const SizedBox(width: 12),
                        _buildMeterIndicator('DIST', preset.effects['distortion'] ?? 0.0),
                      ],
                    ),
                  ],
                ),

                // Badges with glassmorphic styling
                if (widget.showRecommendationBadge || widget.showCompatibilityBadge || widget.allowEdit)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildBadge(preset),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeterIndicator(String label, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GuitarrTypography.labelSmall.copyWith(
              color: GuitarrColors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: GuitarrColors.metronomeInactive,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      _getValueColor(value),
                      _getValueColor(value).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(TonePreset preset) {
    if (widget.showRecommendationBadge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: GuitarrColors.steelGold.withOpacity(0.2),
          border: Border.all(
            color: GuitarrColors.steelGold.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 12,
              color: GuitarrColors.steelGold,
            ),
            const SizedBox(width: 2),
            Text(
              'REC',
              style: GuitarrTypography.labelSmall.copyWith(
                color: GuitarrColors.steelGold,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.showCompatibilityBadge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: GuitarrColors.success.withOpacity(0.2),
          border: Border.all(
            color: GuitarrColors.success.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.check_circle,
          size: 12,
          color: GuitarrColors.success,
        ),
      );
    }

    if (widget.allowEdit) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: GuitarrColors.surface3.withOpacity(0.8),
          border: Border.all(
            color: GuitarrColors.glassBorderSubtle,
            width: 1,
          ),
        ),
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 16,
            color: GuitarrColors.textSecondary,
          ),
          onSelected: (value) {
            // Handle edit actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'clone', child: Text('Clonar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 64,
              color: GuitarrColors.textTertiary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron presets',
              style: GuitarrTypography.titleMedium.copyWith(
                color: GuitarrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta los filtros o crea un nuevo preset',
              style: GuitarrTypography.bodySmall.copyWith(
                color: GuitarrColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenreColor(String genre) {
    return GuitarrColors.getGenreColor(genre);
  }

  Color _getValueColor(double value) {
    if (value < 0.3) return GuitarrColors.success;
    if (value < 0.7) return GuitarrColors.warning;
    return GuitarrColors.error;
  }
}