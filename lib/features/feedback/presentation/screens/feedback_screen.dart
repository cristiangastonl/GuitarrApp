import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../core/services/github_issue_service.dart';
import '../../../../core/services/error_log_service.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _service = GitHubIssueService();
  final _errorLog = ErrorLogService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'bug';
  bool _sending = false;
  bool _sent = false;
  bool _attachLogs = true;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Escribí un título corto');
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = 'Contanos qué pasó');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final url = await _service.createIssue(
      title: title,
      body: body,
      category: _category,
      attachLogs: _attachLogs,
    );

    if (!mounted) return;

    if (url != null) {
      setState(() {
        _sending = false;
        _sent = true;
      });
    } else {
      setState(() {
        _sending = false;
        _error = 'No se pudo enviar. Verificá tu conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArcadeColors.background,
      appBar: AppBar(
        backgroundColor: ArcadeColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ArcadeColors.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const NeonText(
          text: 'FEEDBACK',
          fontSize: 18,
          color: ArcadeColors.neonPink,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _sent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: ArcadeColors.neonGreen,
              size: 64,
            ),
            const SizedBox(height: 24),
            const NeonText(
              text: 'ENVIADO!',
              fontSize: 24,
              color: ArcadeColors.neonGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gracias por tu feedback.\nLo vamos a revisar pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcadeColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ArcadeButton(
              text: 'VOLVER',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).pop(),
              height: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro
          const Text(
            '¿Encontraste un error o tenés una idea?',
            style: TextStyle(
              color: ArcadeColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tu feedback nos ayuda a mejorar la app.',
            style: TextStyle(
              color: ArcadeColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          // Category selector
          const Text(
            'CATEGORÍA',
            style: TextStyle(
              color: ArcadeColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _CategoryChip(
                label: 'Bug',
                icon: Icons.bug_report,
                color: ArcadeColors.neonRed,
                isSelected: _category == 'bug',
                onTap: () => setState(() => _category = 'bug'),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Sugerencia',
                icon: Icons.lightbulb,
                color: ArcadeColors.neonYellow,
                isSelected: _category == 'sugerencia',
                onTap: () => setState(() => _category = 'sugerencia'),
              ),
              const SizedBox(width: 8),
              _CategoryChip(
                label: 'Otro',
                icon: Icons.chat,
                color: ArcadeColors.neonCyan,
                isSelected: _category == 'otro',
                onTap: () => setState(() => _category = 'otro'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'RESUMEN',
            style: TextStyle(
              color: ArcadeColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: ArcadeColors.textPrimary),
            decoration: InputDecoration(
              hintText: _category == 'bug'
                  ? 'Ej: No se escucha el micrófono'
                  : 'Ej: Agregar modo zurdo',
              hintStyle: TextStyle(
                color: ArcadeColors.textMuted.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: ArcadeColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ArcadeColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ArcadeColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: ArcadeColors.neonCyan,
                ),
              ),
            ),
            maxLength: 100,
          ),

          const SizedBox(height: 16),

          // Description
          const Text(
            'DETALLE',
            style: TextStyle(
              color: ArcadeColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            style: const TextStyle(color: ArcadeColors.textPrimary),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _category == 'bug'
                  ? '¿Qué pasó? ¿Qué esperabas que pase?'
                  : 'Contanos tu idea...',
              hintStyle: TextStyle(
                color: ArcadeColors.textMuted.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: ArcadeColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ArcadeColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ArcadeColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: ArcadeColors.neonCyan,
                ),
              ),
            ),
            maxLength: 500,
          ),

          // Auto-attached logs indicator
          if (_errorLog.hasErrors) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArcadeColors.neonOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArcadeColors.neonOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.terminal, size: 18, color: ArcadeColors.neonOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_errorLog.errors.length} error(es) detectado(s)',
                          style: const TextStyle(
                            color: ArcadeColors.neonOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Se adjuntan automáticamente al reporte',
                          style: TextStyle(
                            color: ArcadeColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _attachLogs,
                    onChanged: (v) => setState(() => _attachLogs = v),
                    activeColor: ArcadeColors.neonOrange,
                  ),
                ],
              ),
            ),
          ],

          // Error
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: ArcadeColors.neonRed,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ArcadeButton(
              text: _sending ? 'ENVIANDO...' : 'ENVIAR',
              icon: _sending ? Icons.hourglass_top : Icons.send,
              onPressed: _sending ? null : _submit,
              enabled: !_sending,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : ArcadeColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : ArcadeColors.textMuted,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? NeonEffects.glow(color, intensity: 0.2)
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : ArcadeColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : ArcadeColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
