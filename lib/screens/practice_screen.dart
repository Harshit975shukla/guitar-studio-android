import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../audio/guitar_synthesizer.dart';
import '../core/theme/app_theme.dart';
import '../data/chord_database.dart';
import '../models/music_models.dart';
import 'metronome_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRACTICE & DRILLS'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: '1-MIN CHANGES'),
            Tab(text: 'FRETBOARD QUIZ'),
            Tab(text: 'EAR TRAINING'),
            Tab(text: 'METRONOME & RHYTHM'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OneMinuteChangesView(),
          _FretboardQuizView(),
          _EarTrainingView(),
          MetronomeScreen(),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. One Minute Chord Changes Drill
// ============================================================================
class _OneMinuteChangesView extends StatefulWidget {
  const _OneMinuteChangesView();

  @override
  State<_OneMinuteChangesView> createState() => _OneMinuteChangesViewState();
}

class _OneMinuteChangesViewState extends State<_OneMinuteChangesView> {
  final List<List<String>> _chordPairs = [
    ['G', 'Em'],
    ['C', 'D'],
    ['Am', 'E'],
    ['D', 'A'],
    ['C', 'G'],
    ['Dm', 'Am'],
  ];

  int _selectedPairIdx = 0;
  int _secondsLeft = 60;
  int _changesCount = 0;
  int _bestScore = 0;
  bool _isRunning = false;
  Timer? _timer;
  int _activeChordToggle = 0; // 0 = first chord, 1 = second chord

  void _startTimer() {
    setState(() {
      _secondsLeft = 60;
      _changesCount = 0;
      _isRunning = true;
      _activeChordToggle = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() {
          _isRunning = false;
          _secondsLeft = 0;
          if (_changesCount > _bestScore) {
            _bestScore = _changesCount;
          }
        });
      } else {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 5) {
          GuitarSynthesizer().playClick(accent: true);
        }
      }
    });
  }

  void _onChordTapped() {
    if (!_isRunning) return;
    setState(() {
      _changesCount++;
      _activeChordToggle = (_activeChordToggle + 1) % 2;
    });

    // Strum the active chord sound
    final chordName = _chordPairs[_selectedPairIdx][_activeChordToggle];
    final chord = ChordDatabase.findChord(chordName);
    if (chord != null) {
      GuitarSynthesizer().strumChord(chord.primaryVoicing.frets, TuningPreset.standard);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pair = _chordPairs[_selectedPairIdx];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Pair Chips
          const Text(
            'CHORD PAIR',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_chordPairs.length, (i) {
              final isSel = _selectedPairIdx == i;
              final p = _chordPairs[i];
              return ChoiceChip(
                label: Text('${p[0]} ↔ ${p[1]}'),
                selected: isSel,
                selectedColor: AppTheme.gold,
                backgroundColor: AppTheme.surface,
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (sel) {
                  if (sel && !_isRunning) setState(() => _selectedPairIdx = i);
                },
              );
            }),
          ),

          const SizedBox(height: 24),

          // Timer & Best Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('TIME LEFT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  Text(
                    '${_secondsLeft}s',
                    style: TextStyle(
                      color: _secondsLeft <= 10 ? AppTheme.red : AppTheme.gold,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('CHANGES', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  Text(
                    '$_changesCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('BEST', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  Text(
                    '$_bestScore',
                    style: const TextStyle(
                      color: AppTheme.emerald,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Big Interactive Switch Button
          GestureDetector(
            onTap: _isRunning ? _onChordTapped : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 180,
              decoration: BoxDecoration(
                color: _isRunning
                    ? (_activeChordToggle == 0 ? AppTheme.surfaceElevated : const Color(0xFF1B2838))
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRunning ? AppTheme.gold : AppTheme.surfaceBorder,
                  width: 2.5,
                ),
                boxShadow: _isRunning
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isRunning ? pair[_activeChordToggle] : 'READY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _isRunning ? 'TAP ON EACH SWITCH' : 'Press START below',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Start / Stop Drill Button
          FilledButton.icon(
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(
              _isRunning ? 'RESET' : 'START 1-MINUTE TEST',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _isRunning ? AppTheme.red : AppTheme.gold,
              foregroundColor: _isRunning ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_isRunning) {
                _timer?.cancel();
                setState(() => _isRunning = false);
              } else {
                _startTimer();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. Fretboard Note Trainer Quiz
// ============================================================================
class _FretboardQuizView extends StatefulWidget {
  const _FretboardQuizView();

  @override
  State<_FretboardQuizView> createState() => _FretboardQuizViewState();
}

class _FretboardQuizViewState extends State<_FretboardQuizView> {
  final Random _rng = Random();
  int _questionString = 0; // 0=High e .. 5=Low E
  int _questionFret = 0;
  String _targetNote = 'E';
  int _score = 0;
  int _streak = 0;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _questionString = _rng.nextInt(6);
      _questionFret = _rng.nextInt(13); // frets 0 to 12
      final openMidi = TuningPreset.standard.strings[_questionString].midi;
      _targetNote = kNoteNames[(openMidi + _questionFret) % 12];
      _isCorrect = null;
    });

    // Play prompt sound
    final freq = TuningPreset.standard.strings[_questionString].freq * pow(2.0, _questionFret / 12.0);
    GuitarSynthesizer().pluckString(freq, durationSec: 1.2);
  }

  void _checkAnswer(String chosen) {
    if (_isCorrect != null) return;
    final correct = chosen == _targetNote;
    setState(() {
      _isCorrect = correct;
      if (correct) {
        _score += 10;
        _streak++;
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stringName = TuningPreset.standard.strings[_questionString].gaugeName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SCORE: $_score', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
              Text('STREAK: $_streak 🔥', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Question Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCorrect == null
                    ? AppTheme.surfaceBorder
                    : (_isCorrect! ? AppTheme.emerald : AppTheme.red),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text('WHAT NOTE IS AT:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  stringName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  _questionFret == 0 ? 'OPEN STRING' : 'FRET $_questionFret',
                  style: const TextStyle(color: AppTheme.gold, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Note Answer Buttons (12 Notes)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: kNoteNames.map((n) {
              return SizedBox(
                width: 68,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.surfaceElevated,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                  ),
                  onPressed: () => _checkAnswer(n),
                  child: Text(n, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. Ear Training Quiz (Major vs Minor)
// ============================================================================
class _EarTrainingView extends StatefulWidget {
  const _EarTrainingView();

  @override
  State<_EarTrainingView> createState() => _EarTrainingViewState();
}

class _EarTrainingViewState extends State<_EarTrainingView> {
  final Random _rng = Random();
  String _currentQuality = 'Major'; // 'Major' or 'Minor'
  int _score = 0;
  bool? _answeredCorrectly;

  @override
  void initState() {
    super.initState();
    _playNewChord();
  }

  void _playNewChord() {
    setState(() {
      _currentQuality = _rng.nextBool() ? 'Major' : 'Minor';
      _answeredCorrectly = null;
    });

    _replaySound();
  }

  void _replaySound() {
    final root = kNoteNames[_rng.nextInt(12)];
    final chord = ChordDatabase.findChord('$root${_currentQuality == "Minor" ? "m" : ""}');
    if (chord != null) {
      GuitarSynthesizer().strumChord(chord.primaryVoicing.frets, TuningPreset.standard);
    }
  }

  void _checkEarAnswer(String answer) {
    if (_answeredCorrectly != null) return;
    final isCorrect = answer == _currentQuality;
    setState(() {
      _answeredCorrectly = isCorrect;
      if (isCorrect) _score += 10;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _playNewChord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EAR SCORE: $_score', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Replay Button
          Center(
            child: IconButton.filled(
              iconSize: 48,
              icon: const Icon(Icons.volume_up),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(24),
              ),
              onPressed: _replaySound,
              tooltip: 'Replay Chord Sound',
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Listen carefully: Is it Major or Minor?',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),

          const SizedBox(height: 36),

          // Two Choice Buttons: Major vs Minor
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _answeredCorrectly != null && _currentQuality == 'Major'
                          ? AppTheme.emerald
                          : AppTheme.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.surfaceBorder, width: 2),
                      ),
                    ),
                    onPressed: () => _checkEarAnswer('Major'),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('MAJOR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('Happy, Bright', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _answeredCorrectly != null && _currentQuality == 'Minor'
                          ? AppTheme.emerald
                          : AppTheme.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.surfaceBorder, width: 2),
                      ),
                    ),
                    onPressed: () => _checkEarAnswer('Minor'),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('MINOR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('Sad, Dark', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
