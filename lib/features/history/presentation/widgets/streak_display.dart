import 'package:flutter/material.dart';

class StreakDisplay extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> practiceDates;

  const StreakDisplay({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.practiceDates,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _scaleController;
  late Animation<double> _flameAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flameAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _flameController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _scaleController.forward();
    if (widget.currentStreak > 0) {
      _flameController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.currentStreak > 0
                    ? [
                        Colors.orange.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ]
                    : [
                        Theme.of(context).cardColor,
                        Theme.of(context).cardColor,
                      ],
              ),
              border: Border.all(
                color: widget.currentStreak > 0
                    ? Colors.orange.withOpacity(0.3)
                    : Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStreakStats(),
                const SizedBox(height: 20),
                _buildCalendarView(),
                const SizedBox(height: 16),
                _buildMotivationalMessage(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _flameAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.currentStreak > 0 ? _flameAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.currentStreak > 0
                        ? [Colors.orange, Colors.red]
                        : [Colors.grey.shade400, Colors.grey.shade600],
                  ),
                ),
                child: Icon(
                  widget.currentStreak > 0
                      ? Icons.local_fire_department
                      : Icons.fireplace,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Racha de Práctica',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.currentStreak >= 7)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.withOpacity(0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'En racha!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStreakStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Racha Actual',
            widget.currentStreak.toString(),
            widget.currentStreak == 0 ? 'días' : widget.currentStreak == 1 ? 'día' : 'días',
            widget.currentStreak > 0 ? Colors.orange : Colors.grey,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Mejor Racha',
            widget.longestStreak.toString(),
            widget.longestStreak == 0 ? 'días' : widget.longestStreak == 1 ? 'día' : 'días',
            Colors.amber,
            Icons.emoji_events,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Este Mes',
            widget.practiceDates.length.toString(),
            widget.practiceDates.length == 1 ? 'día' : 'días',
            Theme.of(context).primaryColor,
            Icons.calendar_today,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos 30 días',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 29));
    
    final practiceSet = widget.practiceDates.map((date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }).toSet();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Week days header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
              return SizedBox(
                width: 24,
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          
          // Calendar grid
          Wrap(
            children: List.generate(30, (index) {
              final date = thirtyDaysAgo.add(Duration(days: index));
              final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final hasPractice = practiceSet.contains(dateKey);
              final isToday = date.day == today.day && 
                               date.month == today.month && 
                               date.year == today.year;
              
              return Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPractice
                      ? Colors.orange
                      : isToday
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  border: isToday
                      ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                      : null,
                ),
                child: hasPractice
                    ? const Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.orange, 'Practicaste'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.grey.withOpacity(0.2), 'Sin práctica'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage() {
    String message;
    IconData icon;
    Color color;

    if (widget.currentStreak == 0) {
      message = "¡Empieza tu racha hoy! La práctica consistente es clave para mejorar.";
      icon = Icons.play_arrow;
      color = Theme.of(context).primaryColor;
    } else if (widget.currentStreak < 3) {
      message = "¡Vas bien! Mantén el ritmo para formar un hábito sólido.";
      icon = Icons.trending_up;
      color = Colors.blue;
    } else if (widget.currentStreak < 7) {
      message = "¡Excelente racha! Estás formando un gran hábito de práctica.";
      icon = Icons.favorite;
      color = Colors.orange;
    } else if (widget.currentStreak < 30) {
      message = "¡Increíble! Tu dedicación está dando frutos. ¡Sigue así!";
      icon = Icons.auto_awesome;
      color = Colors.red;
    } else {
      message = "¡Eres una leyenda! Tu constancia es inspiradora. 🎸🔥";
      icon = Icons.star;
      color = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}