import 'package:flutter/material.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomePage({super.key, required this.onNext});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              children: [
                Icon(
                  Icons.music_note,
                  size: 80,
                  color: ArcadeColors.neonPink,
                  shadows: NeonEffects.textGlow(ArcadeColors.neonPink),
                ),
                const SizedBox(height: 16),
                const NeonText(
                  text: 'GUITARR',
                  fontSize: 42,
                  color: ArcadeColors.neonPink,
                ),
                const NeonText(
                  text: 'APP',
                  fontSize: 42,
                  color: ArcadeColors.neonCyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnim,
            child: const Text(
              'Aprende guitarra tocando\ny recibiendo feedback en tiempo real',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcadeColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: _fadeAnim,
            child: ArcadeButton(
              text: 'COMENZAR',
              icon: Icons.arrow_forward,
              onPressed: widget.onNext,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
