import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/arcade_theme.dart';
import '../../../../widgets/neon_text.dart';
import '../../../../widgets/arcade_button.dart';

class MicPermissionPage extends StatefulWidget {
  final VoidCallback onNext;
  final ValueChanged<bool> onPermissionResult;

  const MicPermissionPage({
    super.key,
    required this.onNext,
    required this.onPermissionResult,
  });

  @override
  State<MicPermissionPage> createState() => _MicPermissionPageState();
}

class _MicPermissionPageState extends State<MicPermissionPage> {
  bool _permissionGranted = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web, browser handles permissions via getUserMedia
      _permissionGranted = true;
      widget.onPermissionResult(true);
    }
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      widget.onPermissionResult(true);
      widget.onNext();
      return;
    }

    final status = await Permission.microphone.request();
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionDenied = status.isDenied || status.isPermanentlyDenied;
    });
    widget.onPermissionResult(status.isGranted);

    if (status.isGranted) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Auto-advance on web
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNext());
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: NeonEffects.neonContainer(
              ArcadeColors.neonCyan,
              borderRadius: 20,
            ),
            child: const Icon(
              Icons.mic,
              size: 64,
              color: ArcadeColors.neonCyan,
            ),
          ),
          const SizedBox(height: 32),
          const NeonText(
            text: 'MICROFONO',
            fontSize: 28,
            color: ArcadeColors.neonCyan,
          ),
          const SizedBox(height: 16),
          const Text(
            'Necesitamos acceso al microfono\npara escucharte tocar la guitarra\ny darte feedback en tiempo real.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ArcadeColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (_permissionDenied) ...[
            const SizedBox(height: 16),
            const Text(
              'Permiso denegado. Puedes habilitarlo\nen la configuracion del dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ArcadeColors.neonRed,
                fontSize: 14,
              ),
            ),
          ],
          const Spacer(),
          if (!_permissionGranted)
            ArcadeButton(
              text: 'PERMITIR MICROFONO',
              icon: Icons.mic,
              onPressed: _requestPermission,
            ),
          if (_permissionGranted)
            ArcadeButton(
              text: 'CONTINUAR',
              icon: Icons.arrow_forward,
              onPressed: widget.onNext,
            ),
          if (_permissionDenied) ...[
            const SizedBox(height: 12),
            ArcadeButton.outline(
              text: 'SALTAR',
              onPressed: widget.onNext,
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
