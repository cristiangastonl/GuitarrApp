import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';

/// Arcade-style button with neon glow effect
class ArcadeButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double width;
  final double height;
  final bool enabled;
  final IconData? icon;

  const ArcadeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color = ArcadeColors.neonGreen,
    this.textColor = ArcadeColors.background,
    this.width = double.infinity,
    this.height = 56,
    this.enabled = true,
    this.icon,
  });

  /// Secondary button style
  factory ArcadeButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    double width = double.infinity,
    double height = 56,
    bool enabled = true,
    IconData? icon,
  }) {
    return ArcadeButton(
      key: key,
      text: text,
      onPressed: onPressed,
      color: ArcadeColors.neonCyan,
      width: width,
      height: height,
      enabled: enabled,
      icon: icon,
    );
  }

  /// Outline button style
  factory ArcadeButton.outline({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    Color color = ArcadeColors.neonCyan,
    double width = double.infinity,
    double height = 56,
    bool enabled = true,
    IconData? icon,
  }) {
    return _ArcadeOutlineButton(
      key: key,
      text: text,
      onPressed: onPressed,
      color: color,
      width: width,
      height: height,
      enabled: enabled,
      icon: icon,
    );
  }

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.color : widget.color.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: widget.enabled
                    ? NeonEffects.glow(
                        widget.color,
                        intensity: _isPressed ? 1.5 : 1.0,
                      )
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.textColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.enabled
                            ? widget.textColor
                            : widget.textColor.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Outline variant of arcade button
class _ArcadeOutlineButton extends ArcadeButton {
  const _ArcadeOutlineButton({
    super.key,
    required super.text,
    super.onPressed,
    required super.color,
    required super.width,
    required super.height,
    required super.enabled,
    super.icon,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeOutlineButtonState();
}

class _ArcadeOutlineButtonState extends State<ArcadeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.color : widget.color.withValues(alpha: 0.3);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: effectiveColor, width: 2),
                boxShadow: widget.enabled
                    ? NeonEffects.glow(
                        widget.color,
                        intensity: _isPressed ? 0.8 : 0.4,
                      )
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: effectiveColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: effectiveColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small icon button with neon glow
class ArcadeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;

  const ArcadeIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = ArcadeColors.neonCyan,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: NeonEffects.glow(color, intensity: 0.5),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
