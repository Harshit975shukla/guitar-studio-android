import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/scales_database.dart';
import '../models/music_models.dart';
import '../widgets/fretboard/fretboard_widget.dart';

class ScalesScreen extends StatefulWidget {
  const ScalesScreen({super.key});

  @override
  State<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> {
  String _selectedRoot = 'A';
  ScaleDefinition _selectedScale = ScalesDatabase.allScales.first; // Minor Pentatonic
  bool _showCircleOfFifths = false;

  final List<String> _roots = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];

  Set<String> _computeScaleNotes() {
    final int rootIdx = kNoteNames.indexOf(_selectedRoot);
    final Set<String> notes = {};
    for (final interval in _selectedScale.intervals) {
      final noteName = kNoteNames[(rootIdx + interval) % 12];
      notes.add(noteName);
    }
    return notes;
  }

  @override
  Widget build(BuildContext context) {
    final scaleNotes = _computeScaleNotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCALES & THEORY'),
        actions: [
          IconButton(
            icon: Icon(
              _showCircleOfFifths ? Icons.view_column : Icons.pie_chart,
              color: AppTheme.gold,
            ),
            tooltip: _showCircleOfFifths ? 'Show Fretboard' : 'Show Circle of Fifths',
            onPressed: () => setState(() => _showCircleOfFifths = !_showCircleOfFifths),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Root Selector
            const Text(
              'SCALE ROOT',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _roots.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = _roots[i];
                  final isSel = _selectedRoot == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSel,
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedRoot = r);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Scale Type Chips
            const Text(
              'SCALE TYPE',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScalesDatabase.allScales.map((s) {
                final isSel = _selectedScale.id == s.id;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: isSel,
                  selectedColor: AppTheme.gold,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedScale = s);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Scale Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedRoot ${_selectedScale.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedScale.description,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: scaleNotes.map((n) {
                      final isRoot = n == _selectedRoot;
                      return Chip(
                        label: Text(n),
                        backgroundColor: isRoot ? AppTheme.gold : AppTheme.surfaceElevated,
                        labelStyle: TextStyle(
                          color: isRoot ? Colors.black : AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            if (_showCircleOfFifths) ...[
              const Text(
                'CIRCLE OF FIFTHS',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _CircleOfFifthsWidget(
                selectedKey: _selectedRoot,
                onKeySelect: (k) => setState(() => _selectedRoot = k),
              ),
            ] else ...[
              const Text(
                'FULL FRETBOARD MAP',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: FretboardWidget(
                  totalFrets: 18,
                  tuning: TuningPreset.standard,
                  activeFrets: const [0, 0, 0, 0, 0, 0],
                  rootNote: _selectedRoot,
                  highlightedNotes: scaleNotes,
                  isVertical: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Circle of Fifths Visual Interactive Wheel
class _CircleOfFifthsWidget extends StatelessWidget {
  final String selectedKey;
  final Function(String key) onKeySelect;

  const _CircleOfFifthsWidget({required this.selectedKey, required this.onKeySelect});

  static const List<String> majorKeys = [
    'C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Db', 'Ab', 'Eb', 'Bb', 'F'
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 320,
        height: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.surfaceBorder, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Emblem
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedKey,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Diatonic Root',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),

            // 12 Outer Keys
            ...List.generate(12, (i) {
              final double angle = -pi / 2 + (i * 2 * pi / 12);
              const double r = 120.0;
              final double x = r * cos(angle);
              final double y = r * sin(angle);
              final key = majorKeys[i];
              final isSel = selectedKey == key;

              return Transform.translate(
                offset: Offset(x, y),
                child: InkWell(
                  onTap: () => onKeySelect(key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.gold : AppTheme.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : AppTheme.surfaceBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
