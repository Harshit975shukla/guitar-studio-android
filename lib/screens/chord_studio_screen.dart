import 'package:flutter/material.dart';
import '../audio/guitar_synthesizer.dart';
import '../core/theme/app_theme.dart';
import '../data/chord_database.dart';
import '../models/music_models.dart';
import '../widgets/fretboard/fretboard_widget.dart';

class ChordStudioScreen extends StatefulWidget {
  const ChordStudioScreen({super.key});

  @override
  State<ChordStudioScreen> createState() => _ChordStudioScreenState();
}

class _ChordStudioScreenState extends State<ChordStudioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRoot = 'C';
  String _selectedQuality = 'Major';
  ChordDefinition? _currentChord;
  int _voicingIndex = 0;

  final List<String> _roots = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
  final List<String> _qualities = ['Major', 'Minor', '7', 'maj7', 'm7', 'sus4', 'sus2', '5', 'dim', 'aug'];

  @override
  void initState() {
    super.initState();
    _updateChord();
  }

  void _updateChord() {
    // Generate chord name query
    String qualitySuffix = '';
    if (_selectedQuality == 'Minor') {
      qualitySuffix = 'm';
    } else if (_selectedQuality != 'Major') {
      qualitySuffix = _selectedQuality;
    }

    final query = '$_selectedRoot$qualitySuffix';
    final chord = ChordDatabase.findChord(query);
    setState(() {
      _currentChord = chord ?? ChordDatabase.allChords.first;
      _voicingIndex = 0;
    });
  }

  void _strumChord({bool downstroke = true}) {
    if (_currentChord != null && _currentChord!.voicings.isNotEmpty) {
      final frets = _currentChord!.voicings[_voicingIndex].frets;
      GuitarSynthesizer().strumChord(frets, TuningPreset.standard, downstroke: downstroke);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChordVoicing? activeVoicing = (_currentChord != null && _currentChord!.voicings.isNotEmpty)
        ? _currentChord!.voicings[_voicingIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHORD STUDIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: AppTheme.gold),
            tooltip: 'Downstroke Strum',
            onPressed: () => _strumChord(downstroke: true),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: AppTheme.gold),
            tooltip: 'Upstroke Strum',
            onPressed: () => _strumChord(downstroke: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Field
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search any chord (e.g. C, F#m, D7, Bm7)...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (query) {
                final found = ChordDatabase.findChord(query);
                if (found != null) {
                  setState(() {
                    _currentChord = found;
                    _selectedRoot = found.root;
                    _selectedQuality = found.quality;
                    _voicingIndex = 0;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Root Selector Carousel
            const Text(
              'ROOT NOTE',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _roots.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = _roots[i];
                  final isSelected = _selectedRoot == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSelected,
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRoot = r);
                        _updateChord();
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Quality Selector
            const Text(
              'CHORD TYPE',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _qualities.map((q) {
                final isSelected = _selectedQuality == q;
                return ChoiceChip(
                  label: Text(q),
                  selected: isSelected,
                  selectedColor: AppTheme.gold,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedQuality = q);
                      _updateChord();
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Chord Header & Voicing Selector
            if (_currentChord != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentChord!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Formula: ${_currentChord!.formula} (${_currentChord!.notes.join(" - ")})',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),

                    // Strum button
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('STRUM'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _strumChord(downstroke: true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Voicing selector tabs if multiple voicings exist
              if (_currentChord!.voicings.length > 1) ...[
                Row(
                  children: [
                    const Text('Voicings: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_currentChord!.voicings.length, (i) {
                            final v = _currentChord!.voicings[i];
                            final isSel = _voicingIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(v.name),
                                selected: isSel,
                                selectedColor: AppTheme.surfaceElevated,
                                side: BorderSide(color: isSel ? AppTheme.gold : AppTheme.surfaceBorder),
                                labelStyle: TextStyle(
                                  color: isSel ? AppTheme.gold : Colors.white70,
                                  fontSize: 11,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _voicingIndex = i);
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],

            const SizedBox(height: 8),

            // Fretboard Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: FretboardWidget(
                totalFrets: 15,
                tuning: TuningPreset.standard,
                activeFrets: activeVoicing?.frets ?? [null, null, null, null, null, null],
                fingerNumbers: activeVoicing?.fingers,
                rootNote: _currentChord?.root,
                isVertical: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
