import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/guitar_synthesizer.dart';
import '../core/theme/app_theme.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  int _bpm = 100;
  int _beatsPerBar = 4;
  int _currentBeat = 0;
  bool _isPlaying = false;
  Timer? _timer;

  // Tap tempo
  final List<DateTime> _tapTimes = [];

  final List<int> _timeSignatures = [2, 3, 4, 6];

  final List<Map<String, String>> _strumPatterns = [
    {'name': 'Folk / Island Strum', 'pattern': 'D - D U - U D U', 'meter': '4/4'},
    {'name': 'Classic Rock Drive', 'pattern': 'D - D - D - D -', 'meter': '4/4'},
    {'name': 'Pop Acoustic Pulse', 'pattern': 'D - - U D - - U', 'meter': '4/4'},
    {'name': 'Waltz Ballad', 'pattern': 'D - D - D -', 'meter': '3/4'},
    {'name': 'Keharwa Taal (Indian 8-beat)', 'pattern': 'Dha Ge Na Ti | Na Ke Dhi Na', 'meter': '4/4'},
    {'name': 'Dadra Taal (Indian 6-beat)', 'pattern': 'Dha Dhi Na | Dha Tu Na', 'meter': '6/8'},
  ];

  void _togglePlay() {
    if (_isPlaying) {
      _stopMetronome();
    } else {
      _startMetronome();
    }
  }

  void _startMetronome() {
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });

    final int intervalMs = (60000 / _bpm).round();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (!mounted) return;
      setState(() {
        _currentBeat = (_currentBeat + 1) % _beatsPerBar;
      });
      final bool isAccent = _currentBeat == 0;
      GuitarSynthesizer().playClick(accent: isAccent);
    });
  }

  void _stopMetronome() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _tapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);
    if (_tapTimes.length > 4) {
      _tapTimes.removeAt(0);
    }
    if (_tapTimes.length >= 2) {
      int totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs += _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final double avgMs = totalMs / (_tapTimes.length - 1);
      final int calculatedBpm = (60000 / avgMs).round().clamp(40, 240);
      setState(() => _bpm = calculatedBpm);
      if (_isPlaying) {
        _startMetronome();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RHYTHM & METRONOME'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BPM Hero Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$_bpm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BPM',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Beat Visualizer Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_beatsPerBar, (i) {
                      final isActive = _isPlaying && _currentBeat == i;
                      final isFirst = i == 0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: isActive ? 22 : 14,
                        height: isActive ? 22 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? (isFirst ? AppTheme.emerald : AppTheme.gold)
                              : const Color(0xFF1E293B),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: (isFirst ? AppTheme.emerald : AppTheme.gold)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // BPM Slider
                  Slider(
                    value: _bpm.toDouble(),
                    min: 40,
                    max: 220,
                    activeColor: AppTheme.gold,
                    inactiveColor: const Color(0xFF1E293B),
                    onChanged: (v) {
                      setState(() => _bpm = v.round());
                      if (_isPlaying) _startMetronome();
                    },
                  ),

                  // Quick Adjustment Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Text('-5', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() => _bpm = (_bpm - 5).clamp(40, 240));
                          if (_isPlaying) _startMetronome();
                        },
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.surfaceElevated,
                          foregroundColor: AppTheme.gold,
                        ),
                        onPressed: _tapTempo,
                        child: const Text('TAP TEMPO'),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filledTonal(
                        icon: const Text('+5', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() => _bpm = (_bpm + 5).clamp(40, 240));
                          if (_isPlaying) _startMetronome();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Big Start / Stop Button
            FilledButton.icon(
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 28),
              label: Text(
                _isPlaying ? 'STOP METRONOME' : 'START METRONOME',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isPlaying ? AppTheme.red : AppTheme.gold,
                foregroundColor: _isPlaying ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _togglePlay,
            ),

            const SizedBox(height: 24),

            // Time Signature Selector
            const Text(
              'TIME SIGNATURE',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _timeSignatures.map((sig) {
                final isSel = _beatsPerBar == sig;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: Text('$sig/4')),
                      selected: isSel,
                      selectedColor: AppTheme.gold,
                      backgroundColor: AppTheme.surface,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (sel) {
                        if (sel) {
                          setState(() => _beatsPerBar = sig);
                          if (_isPlaying) _startMetronome();
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Strumming Patterns Card
            const Text(
              'STRUMMING & RHYTHM PATTERNS',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._strumPatterns.map((pat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pat['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pat['pattern']!,
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pat['meter']!,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
