import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/session.dart';
import '../../../../core/services/optimized_database_service.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Provider for paginated sessions
final paginatedSessionsProvider = StateNotifierProvider.family<
    PaginatedSessionsNotifier, 
    AsyncValue<List<Session>>, 
    String
>((ref, userId) {
  return PaginatedSessionsNotifier(userId);
});

class PaginatedSessionsNotifier extends StateNotifier<AsyncValue<List<Session>>> {
  final String userId;
  final OptimizedDatabaseService _databaseService = OptimizedDatabaseService();
  
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  List<Session> _allSessions = [];

  PaginatedSessionsNotifier(this.userId) : super(const AsyncValue.loading()) {
    loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || state.isLoading) return;

    try {
      if (_currentPage == 0) {
        state = const AsyncValue.loading();
      }

      final newSessions = await _databaseService.getUserSessions(
        userId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (newSessions.length < _pageSize) {
        _hasMore = false;
      }

      _allSessions.addAll(newSessions);
      _currentPage++;

      state = AsyncValue.data(List.from(_allSessions));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _currentPage = 0;
    _hasMore = true;
    _allSessions.clear();
    loadNextPage();
  }

  bool get hasMore => _hasMore;
}

class OptimizedSessionsList extends ConsumerStatefulWidget {
  final String userId;

  const OptimizedSessionsList({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<OptimizedSessionsList> createState() => _OptimizedSessionsListState();
}

class _OptimizedSessionsListState extends ConsumerState<OptimizedSessionsList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near the bottom
      ref.read(paginatedSessionsProvider(widget.userId).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(paginatedSessionsProvider(widget.userId));
    final notifier = ref.read(paginatedSessionsProvider(widget.userId).notifier);

    return RefreshIndicator(
      onRefresh: () async {
        notifier.refresh();
      },
      child: sessionsAsync.when(
        data: (sessions) => _buildSessionsList(sessions, notifier.hasMore),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  Widget _buildSessionsList(List<Session> sessions, bool hasMore) {
    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay sesiones registradas', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sessions.length) {
          // Loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final session = sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptimizedSessionCard(session: session),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(paginatedSessionsProvider(widget.userId).notifier).refresh();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class OptimizedSessionCard extends StatelessWidget {
  final Session session;

  const OptimizedSessionCard({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to optimize repaints
    return RepaintBoundary(
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: session.completed ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(session.startTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${session.durationMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                _buildStatItem(
                  context,
                  'BPM',
                  '${session.actualBpm}/${session.targetBpm}',
                  Icons.speed,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context,
                  'Precisión',
                  '${(session.accuracy * 100).round()}%',
                  Icons.target,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  context,
                  'Intentos',
                  '${session.successfulRuns}/${session.totalAttempts}',
                  Icons.repeat,
                ),
              ],
            ),
            
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                session.notes,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}