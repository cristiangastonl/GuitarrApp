import 'package:flutter/material.dart';
import '../../../../core/services/achievements_service.dart';

class AchievementsGrid extends StatefulWidget {
  final List<Achievement> achievements;
  final Function(Achievement)? onAchievementTap;

  const AchievementsGrid({
    super.key,
    required this.achievements,
    this.onAchievementTap,
  });

  @override
  State<AchievementsGrid> createState() => _AchievementsGridState();
}

class _AchievementsGridState extends State<AchievementsGrid>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        _buildStatsOverview(),
        const SizedBox(height: 20),
        _buildAchievementsGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.emoji_events,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          'Logros',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _buildTotalPoints(),
      ],
    );
  }

  Widget _buildTotalPoints() {
    final totalPoints = widget.achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$totalPoints pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'label': 'Todos', 'icon': Icons.grid_view},
      {'id': 'practice', 'label': 'Práctica', 'icon': Icons.music_note},
      {'id': 'score', 'label': 'Score', 'icon': Icons.emoji_events},
      {'id': 'streak', 'label': 'Racha', 'icon': Icons.local_fire_department},
      {'id': 'speed', 'label': 'Velocidad', 'icon': Icons.speed},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category['id'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedCategory = category['id'] as String;
                });
                _fadeController.reset();
                _fadeController.forward();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final unlocked = widget.achievements.where((a) => a.isUnlocked).length;
    final total = widget.achievements.length;
    final percentage = (unlocked / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso de Logros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlocked de $total desbloqueados',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: unlocked / total,
                  backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    final filteredAchievements = _getFilteredAchievements();

    if (filteredAchievements.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeController.value,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredAchievements.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final animationValue = (_scaleController.value - delay).clamp(0.0, 1.0);
                  
                  return Transform.scale(
                    scale: animationValue,
                    child: _buildAchievementCard(filteredAchievements[index]),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    
    return InkWell(
      onTap: () {
        if (widget.onAchievementTap != null) {
          widget.onAchievementTap!(achievement);
        } else {
          _showAchievementDetails(achievement);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUnlocked
              ? _getBadgeColor(achievement.badgeColor).withOpacity(0.1)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isUnlocked
                ? _getBadgeColor(achievement.badgeColor).withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: _getBadgeColor(achievement.badgeColor).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? _getBadgeColor(achievement.badgeColor)
                    : Theme.of(context).dividerColor.withOpacity(0.3),
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                color: isUnlocked
                    ? Colors.white
                    : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? Theme.of(context).textTheme.titleMedium?.color
                    : Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Points
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getBadgeColor(achievement.badgeColor).withOpacity(0.2),
                ),
                child: Text(
                  '${achievement.points} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getBadgeColor(achievement.badgeColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                '🔒',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay logros en esta categoría',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  List<Achievement> _getFilteredAchievements() {
    if (selectedCategory == 'all') {
      return widget.achievements;
    }
    
    final typeMap = {
      'practice': AchievementType.practice,
      'score': AchievementType.score,
      'streak': AchievementType.streak,
      'speed': AchievementType.speed,
      'consistency': AchievementType.consistency,
      'milestone': AchievementType.milestone,
    };
    
    final filterType = typeMap[selectedCategory];
    if (filterType == null) return widget.achievements;
    
    return widget.achievements.where((a) => a.type == filterType).toList();
  }

  Color _getBadgeColor(String colorName) {
    switch (colorName) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'red':
        return const Color(0xFFF44336);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'green':
        return const Color(0xFF4CAF50);
      case 'blue':
      default:
        return Theme.of(context).primaryColor;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'play_circle':
        return Icons.play_circle;
      case 'music_note':
        return Icons.music_note;
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'trending_up':
        return Icons.trending_up;
      case 'timer':
        return Icons.timer;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'whatshot':
        return Icons.whatshot;
      case 'speed':
        return Icons.speed;
      case 'fast_forward':
        return Icons.fast_forward;
      case 'flash_on':
        return Icons.flash_on;
      case 'balance':
        return Icons.balance;
      case 'adjust':
        return Icons.adjust;
      case 'schedule':
        return Icons.schedule;
      case 'access_time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.isUnlocked
                    ? _getBadgeColor(achievement.badgeColor)
                    : Theme.of(context).dividerColor.withOpacity(0.3),
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                color: achievement.isUnlocked
                    ? Colors.white
                    : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getBadgeColor(achievement.badgeColor).withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _getBadgeColor(achievement.badgeColor),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Desbloqueado • ${achievement.points} puntos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getBadgeColor(achievement.badgeColor),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (achievement.unlockedDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Obtenido el ${_formatDate(achievement.unlockedDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requisito: ${achievement.requirement}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}