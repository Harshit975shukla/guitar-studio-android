import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/guitar_synthesizer.dart';
import '../core/theme/app_theme.dart';
import '../models/music_models.dart';
import '../services/audio_input_service.dart';
import '../widgets/tuner/headstock_widget.dart';
import '../widgets/tuner/tuner_meter.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final AudioInputService _audioService = AudioInputService();
  StreamSubscription<DetectionResult>? _subscription;

  TuningPreset _selectedTuning = TuningPreset.standard;
  int? _selectedStringIndex; // null = auto detect
  Pitch? _currentPitch;

  @override
  void initState() {
    super.initState();
    _startTuningMic();
  }

  Future<void> _startTuningMic() async {
    await _audioService.startListening();

    _subscription = _audioService.detectionStream.listen((res) {
      if (!mounted) return;
      if (res.detectedPitch != null) {
        setState(() {
          _currentPitch = res.detectedPitch;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _audioService.stopListening();
    super.dispose();
  }

  void _onPegSelected(int stringIndex) {
    setState(() {
      _selectedStringIndex = stringIndex;
    });
    // Play reference pitch for that string
    final str = _selectedTuning.strings[stringIndex];
    GuitarSynthesizer().pluckString(str.freq, durationSec: 2.5);
  }

  @override
  Widget build(BuildContext context) {
    // Determine target note and frequency
    String targetNote = 'E';
    double targetFreq = 82.41;

    if (_selectedStringIndex != null) {
      final str = _selectedTuning.strings[_selectedStringIndex!];
      targetNote = str.note;
      targetFreq = str.freq;
    } else if (_currentPitch != null) {
      // Auto find nearest guitar string
      StringTuning? nearest;
      double minDiff = 1e9;
      for (final s in _selectedTuning.strings) {
        final diff = (s.freq - _currentPitch!.freq).abs();
        if (diff < minDiff) {
          minDiff = diff;
          nearest = s;
        }
      }
      if (nearest != null) {
        targetNote = nearest.note;
        targetFreq = nearest.freq;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GUITAR TUNER'),
        actions: [
          // Tuning preset dropdown
          PopupMenuButton<TuningPreset>(
            initialValue: _selectedTuning,
            icon: const Icon(Icons.tune, color: AppTheme.gold),
            onSelected: (p) => setState(() => _selectedTuning = p),
            itemBuilder: (context) => TuningPreset.presets
                .map((p) => PopupMenuItem(value: p, child: Text(p.name)))
                .toList(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Tuning Mode Banner
            Text(
              _selectedTuning.name,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedStringIndex == null
                  ? 'Auto-detecting string • Tap a peg to lock & play reference'
                  : 'Locked on String ${_selectedTuning.strings[_selectedStringIndex!].gaugeName}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),

            // Tuner Meter Gauge
            TunerMeter(
              pitch: _currentPitch,
              targetNote: targetNote,
              targetFreq: targetFreq,
            ),

            const SizedBox(height: 12),

            // Headstock with 6 interactive pegs
            HeadstockWidget(
              tuning: _selectedTuning,
              activeStringIndex: _selectedStringIndex,
              detectedPitch: _currentPitch,
              onPegSelect: _onPegSelected,
            ),

            if (_selectedStringIndex != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Back to Auto-Detect'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.gold),
                onPressed: () => setState(() => _selectedStringIndex = null),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
