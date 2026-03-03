import 'package:flutter/material.dart';
import '../core/theme/arcade_theme.dart';
import 'hand_diagram.dart';

/// A collapsible reference panel with 3 tabs: Dedos, Cuerdas, Glosario.
/// Uses local setState (no Riverpod).
class ReferencePanel extends StatefulWidget {
  const ReferencePanel({super.key});

  @override
  State<ReferencePanel> createState() => _ReferencePanelState();
}

class _ReferencePanelState extends State<ReferencePanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  int _selectedTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle bar
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ArcadeColors.backgroundLight,
              border: Border(
                top: BorderSide(
                  color: ArcadeColors.neonCyan.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 16,
                  color: ArcadeColors.neonCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  'REFERENCIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ArcadeColors.neonCyan,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.expand_less,
                  size: 18,
                  color: ArcadeColors.neonCyan,
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: SizedBox(
            height: 240,
            child: Column(
              children: [
                // Tabs
                Container(
                  color: ArcadeColors.backgroundLight,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: ArcadeColors.neonCyan,
                    labelColor: ArcadeColors.neonCyan,
                    unselectedLabelColor: ArcadeColors.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    tabs: const [
                      Tab(text: 'DEDOS'),
                      Tab(text: 'CUERDAS'),
                      Tab(text: 'GLOSARIO'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: Container(
                    color: ArcadeColors.background,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _FingersTab(),
                        _StringsTab(),
                        _GlossaryTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FingersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fingers = [
      (1, 'Índice', FingerColors.index),
      (2, 'Medio', FingerColors.middle),
      (3, 'Anular', FingerColors.ring),
      (4, 'Meñique', FingerColors.pinky),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: fingers.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: f.$3,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${f.$1}',
                    style: const TextStyle(
                      color: ArcadeColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dedo ${f.$1} — ${f.$2}',
                style: TextStyle(
                  color: f.$3,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StringsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = [
      ('6ª', 'E', 'Mi grave', 3.0),
      ('5ª', 'A', 'La', 2.5),
      ('4ª', 'D', 'Re', 2.0),
      ('3ª', 'G', 'Sol', 1.5),
      ('2ª', 'B', 'Si', 1.0),
      ('1ª', 'e', 'Mi agudo', 0.8),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: strings.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  s.$1,
                  style: const TextStyle(
                    color: ArcadeColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              // Visual string thickness
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    height: s.$4,
                    decoration: BoxDecoration(
                      color: ArcadeColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                child: Text(
                  s.$2,
                  style: const TextStyle(
                    color: ArcadeColors.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  s.$3,
                  style: const TextStyle(
                    color: ArcadeColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GlossaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final terms = [
      ('Traste', 'Espacio entre barras metálicas del mástil'),
      ('Cejilla (Nut)', 'Pieza al inicio del mástil que separa cuerdas'),
      ('Cejilla/Barré', 'Técnica: un dedo pisa varias cuerdas'),
      ('Acorde', 'Combinación de 3+ notas tocadas juntas'),
      ('Mástil', 'Parte larga de la guitarra con trastes'),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: terms.map((t) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.$1,
                style: const TextStyle(
                  color: ArcadeColors.neonPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.$2,
                style: const TextStyle(
                  color: ArcadeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
