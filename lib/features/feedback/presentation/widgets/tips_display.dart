import 'package:flutter/material.dart';
import '../../../../core/services/tips_engine_service.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Widget that displays practice tips and recommendations
class TipsDisplay extends StatelessWidget {
  final List<PracticeTip> tips;
  
  const TipsDisplay({
    super.key,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) {
      return _EmptyTipsPlaceholder();
    }
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Consejos Personalizados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tips.length} tip${tips.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tips list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _TipCard(
                  tip: tips[index],
                  index: index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual tip card with styling based on priority
class _TipCard extends StatefulWidget {
  final PracticeTip tip;
  final int index;
  
  const _TipCard({
    required this.tip,
    required this.index,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 200)),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start animation with delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getTipColors(widget.tip.priority, context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.background,
                    colors.background.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with priority and category
                    Row(
                      children: [
                        _PriorityBadge(priority: widget.tip.priority),
                        const SizedBox(width: 8),
                        _CategoryBadge(category: widget.tip.category),
                        const Spacer(),
                        Text(
                          widget.tip.category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      widget.tip.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.title,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      widget.tip.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Actionable advice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.actionBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.actionBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            color: colors.actionIcon,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.tip.actionable,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.actionText,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  _TipColorScheme _getTipColors(TipPriority priority, BuildContext context) {
    switch (priority) {
      case TipPriority.critical:
        return _TipColorScheme(
          primary: Colors.red[600]!,
          background: Colors.red[50]!,
          border: Colors.red[200]!,
          title: Colors.red[800]!,
          text: Colors.red[700]!,
          actionBackground: Colors.red[100]!,
          actionBorder: Colors.red[300]!,
          actionIcon: Colors.red[600]!,
          actionText: Colors.red[700]!,
        );
      
      case TipPriority.important:
        return _TipColorScheme(
          primary: Colors.orange[600]!,
          background: Colors.orange[50]!,
          border: Colors.orange[200]!,
          title: Colors.orange[800]!,
          text: Colors.orange[700]!,
          actionBackground: Colors.orange[100]!,
          actionBorder: Colors.orange[300]!,
          actionIcon: Colors.orange[600]!,
          actionText: Colors.orange[700]!,
        );
      
      case TipPriority.helpful:
        return _TipColorScheme(
          primary: Colors.blue[600]!,
          background: Colors.blue[50]!,
          border: Colors.blue[200]!,
          title: Colors.blue[800]!,
          text: Colors.blue[700]!,
          actionBackground: Colors.blue[100]!,
          actionBorder: Colors.blue[300]!,
          actionIcon: Colors.blue[600]!,
          actionText: Colors.blue[700]!,
        );
      
      case TipPriority.motivational:
        return _TipColorScheme(
          primary: Colors.green[600]!,
          background: Colors.green[50]!,
          border: Colors.green[200]!,
          title: Colors.green[800]!,
          text: Colors.green[700]!,
          actionBackground: Colors.green[100]!,
          actionBorder: Colors.green[300]!,
          actionIcon: Colors.green[600]!,
          actionText: Colors.green[700]!,
        );
    }
  }
}

/// Color scheme for tips
class _TipColorScheme {
  final Color primary;
  final Color background;
  final Color border;
  final Color title;
  final Color text;
  final Color actionBackground;
  final Color actionBorder;
  final Color actionIcon;
  final Color actionText;
  
  const _TipColorScheme({
    required this.primary,
    required this.background,
    required this.border,
    required this.title,
    required this.text,
    required this.actionBackground,
    required this.actionBorder,
    required this.actionIcon,
    required this.actionText,
  });
}

/// Priority badge widget
class _PriorityBadge extends StatelessWidget {
  final TipPriority priority;
  
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getPriorityColor(TipPriority priority) {
    switch (priority) {
      case TipPriority.critical:
        return Colors.red[600]!;
      case TipPriority.important:
        return Colors.orange[600]!;
      case TipPriority.helpful:
        return Colors.blue[600]!;
      case TipPriority.motivational:
        return Colors.green[600]!;
    }
  }
}

/// Category badge widget
class _CategoryBadge extends StatelessWidget {
  final TipCategory category;
  
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Empty state when no tips are available
class _EmptyTipsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay consejos disponibles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Practica más para recibir consejos personalizados',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact tips display for smaller spaces
class CompactTipsDisplay extends StatelessWidget {
  final List<PracticeTip> tips;
  final int maxTips;
  
  const CompactTipsDisplay({
    super.key,
    required this.tips,
    this.maxTips = 2,
  });

  @override
  Widget build(BuildContext context) {
    final displayTips = tips.take(maxTips).toList();
    
    if (displayTips.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consejos Rápidos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...displayTips.map((tip) => _CompactTipCard(tip: tip)),
      ],
    );
  }
}

/// Compact tip card for small displays
class _CompactTipCard extends StatelessWidget {
  final PracticeTip tip;
  
  const _CompactTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(tip.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            tip.category.icon,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Color _getPriorityColor(TipPriority priority) {
    switch (priority) {
      case TipPriority.critical:
        return Colors.red[600]!;
      case TipPriority.important:
        return Colors.orange[600]!;
      case TipPriority.helpful:
        return Colors.blue[600]!;
      case TipPriority.motivational:
        return Colors.green[600]!;
    }
  }
}

/// Tips summary widget for quick overview
class TipsSummary extends StatelessWidget {
  final List<PracticeTip> tips;
  
  const TipsSummary({
    super.key,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
    
    final priorityCounts = <TipPriority, int>{};
    for (final tip in tips) {
      priorityCounts[tip.priority] = (priorityCounts[tip.priority] ?? 0) + 1;
    }
    
    return Row(
      children: [
        Icon(
          Icons.lightbulb,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '${tips.length} consejos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (priorityCounts[TipPriority.critical] != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${priorityCounts[TipPriority.critical]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}