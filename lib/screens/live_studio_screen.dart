import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/guitar_synthesizer.dart';
import '../core/theme/app_theme.dart';
import '../data/chord_database.dart';
import '../models/music_models.dart';
import '../services/audio_input_service.dart';
import '../widgets/fretboard/fretboard_widget.dart';

class LiveStudioScreen extends StatefulWidget {
  const LiveStudioScreen({super.key});

  @override
  State<LiveStudioScreen> createState() => _LiveStudioScreenState();
}

class _LiveStudioScreenState extends State<LiveStudioScreen> {
  final AudioInputService _audioService = AudioInputService();
  StreamSubscription<DetectionResult>? _subscription;

  DetectionResult _lastResult = DetectionResult(timestamp: DateTime.now());
  ChordDefinition? _activeChord;
  bool _isListening = false;
  bool _isVerticalFretboard = false;
  String _targetMode = 'Chords'; // 'Chords', 'Notes', 'Auto'

  @override
  void initState() {
    super.initState();
    _activeChord = ChordDatabase.findChord('C');
    _subscription = _audioService.detectionStream.listen((res) {
      if (!mounted) return;
      setState(() {
        _lastResult = res;
        if (res.chordName != null && res.chordName!.isNotEmpty) {
          final found = ChordDatabase.findChord(res.chordName!);
          if (found != null) {
            _activeChord = found;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _audioService.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      final success = await _audioService.startListening();
      if (mounted) setState(() => _isListening = success);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for live listening'),
            backgroundColor: AppTheme.red,
          ),
        );
      }
    }
  }

  void _strumCurrentChord() {
    if (_activeChord != null) {
      final frets = _activeChord!.primaryVoicing.frets;
      GuitarSynthesizer().strumChord(frets, TuningPreset.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chordName = _lastResult.chordName ?? _activeChord?.name ?? 'Ready';
    final hasPitch = _lastResult.detectedPitch != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('LIVE STUDIO'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isListening
                    ? AppTheme.emerald.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isListening ? AppTheme.emerald : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isListening ? AppTheme.emerald : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isListening ? 'LISTENING' : 'OFFLINE',
                    style: TextStyle(
                      color: _isListening ? AppTheme.emerald : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rotate Fretboard',
            icon: Icon(
              _isVerticalFretboard ? Icons.screen_lock_landscape : Icons.screen_lock_portrait,
              color: AppTheme.gold,
            ),
            onPressed: () => setState(() => _isVerticalFretboard = !_isVerticalFretboard),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Detection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening ? AppTheme.gold.withValues(alpha: 0.5) : AppTheme.surfaceBorder,
                  width: 1.5,
                ),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Target Mode Selector
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Chords', label: Text('Chords', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'Notes', label: Text('Notes', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: 'Auto', label: Text('Auto', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_targetMode},
                        onSelectionChanged: (set) => setState(() => _targetMode = set.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? AppTheme.gold.withValues(alpha: 0.25)
                                : AppTheme.surfaceElevated,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) ? AppTheme.gold : Colors.white70,
                          ),
                        ),
                      ),

                      // Strum Audio Trigger
                      IconButton.filled(
                        icon: const Icon(Icons.volume_up, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _strumCurrentChord,
                        tooltip: 'Strum Chord Audio',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Big Chord Name Display
                  Text(
                    chordName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),

                  if (_activeChord != null)
                    Text(
                      '${_activeChord!.quality} • ${_activeChord!.formula}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),

                  const SizedBox(height: 16),

                  // Live Pitch & Confidence Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasPitch) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.emerald, width: 1),
                          ),
                          child: Text(
                            'Pitch: ${_lastResult.detectedPitch!.fullNoteName} (${_lastResult.detectedPitch!.freq.toStringAsFixed(1)}Hz)',
                            style: const TextStyle(
                              color: AppTheme.emerald,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Text(
                          'Signal: ${_lastResult.signalLevelDb.toStringAsFixed(0)} dB',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Start / Stop Microphone Button
            FilledButton.icon(
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(
                _isListening ? 'STOP LISTENING' : 'START LISTENING',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isListening ? AppTheme.red : AppTheme.gold,
                foregroundColor: _isListening ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _toggleListening,
            ),

            const SizedBox(height: 24),

            // Fretboard Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INTERACTIVE FRETBOARD',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _activeChord?.primaryVoicing.name ?? 'Standard',
                  style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Fretboard View
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: FretboardWidget(
                totalFrets: 15,
                tuning: TuningPreset.standard,
                activeFrets: _activeChord?.primaryVoicing.frets ?? [null, null, null, null, null, null],
                fingerNumbers: _activeChord?.primaryVoicing.fingers,
                rootNote: _activeChord?.root,
                detectedPitch: _lastResult.detectedPitch,
                isVertical: _isVerticalFretboard,
              ),
            ),

            const SizedBox(height: 20),

            // Quick Chord Suggestion Chips
            const Text(
              'QUICK PRACTICE CHORDS',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['C', 'G', 'D', 'Em', 'Am', 'F', 'A', 'E', 'Dm', 'B7'].map((name) {
                final isSelected = _activeChord?.name == name;
                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppTheme.gold,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      final c = ChordDatabase.findChord(name);
                      if (c != null) {
                        setState(() => _activeChord = c);
                        _strumCurrentChord();
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
