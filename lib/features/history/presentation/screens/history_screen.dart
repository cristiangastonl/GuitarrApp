import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu Progreso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            _StatsCardsSection(),
            
            SizedBox(height: 24),
            
            Text(
              'Sesiones Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 12),
            
            Expanded(
              child: _RecentSessionsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCardsSection extends StatelessWidget {
  const _StatsCardsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Sesiones',
            value: '42',
            subtitle: 'Esta semana',
            icon: Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Mejor Score',
            value: '87',
            subtitle: 'Enter Sandman',
            icon: Icons.emoji_events,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Tiempo Total',
            value: '12h',
            subtitle: 'Este mes',
            icon: Icons.access_time,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList();

  @override
  Widget build(BuildContext context) {
    final sessions = [
      SessionData(
        riff: 'Enter Sandman',
        bpm: 96,
        score: 87,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 15),
      ),
      SessionData(
        riff: 'Paranoid',
        bpm: 140,
        score: 72,
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 12),
      ),
      SessionData(
        riff: 'Back in Black',
        bpm: 88,
        score: 65,
        date: DateTime.now().subtract(const Duration(days: 2)),
        duration: const Duration(minutes: 18),
      ),
      SessionData(
        riff: 'Enter Sandman',
        bpm: 88,
        score: 91,
        date: DateTime.now().subtract(const Duration(days: 3)),
        duration: const Duration(minutes: 20),
      ),
    ];

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(session: session);
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionData session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final scoreColor = session.score >= 80 
        ? Colors.green 
        : session.score >= 60 
            ? Colors.orange 
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor.withValues(alpha: 0.2),
          child: Text(
            session.score.toString(),
            style: TextStyle(
              color: scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.riff,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${session.bpm} BPM • ${_formatDuration(session.duration)} • ${_formatDate(session.date)}',
        ),
        trailing: Icon(
          session.score >= 80 ? Icons.trending_up : Icons.trending_flat,
          color: scoreColor,
        ),
        onTap: () {
          // Navigate to detailed session view
          _showSessionDetails(context, session);
        },
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
  
  void _showSessionDetails(BuildContext context, SessionData session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.riff),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${session.score}/100'),
            Text('BPM: ${session.bpm}'),
            Text('Duración: ${_formatDuration(session.duration)}'),
            Text('Fecha: ${_formatDate(session.date)}'),
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
}

class SessionData {
  final String riff;
  final int bpm;
  final int score;
  final DateTime date;
  final Duration duration;

  SessionData({
    required this.riff,
    required this.bpm,
    required this.score,
    required this.date,
    required this.duration,
  });
}