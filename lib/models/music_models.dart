import 'dart:math';

const List<String> kNoteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

class Pitch {
  final int midi;
  final double freq;
  final String note;
  final int octave;
  final int cents;

  const Pitch({
    required this.midi,
    required this.freq,
    required this.note,
    required this.octave,
    required this.cents,
  });

  static Pitch fromMidi(double midiValue) {
    final int roundedMidi = midiValue.round();
    final int noteIndex = ((roundedMidi % 12) + 12) % 12;
    final String note = kNoteNames[noteIndex];
    final int octave = (roundedMidi ~/ 12) - 1;
    final double freq = 440.0 * pow(2.0, (midiValue - 69.0) / 12.0);
    final int cents = ((midiValue - roundedMidi) * 100.0).round();
    return Pitch(
      midi: roundedMidi,
      freq: freq,
      note: note,
      octave: octave,
      cents: cents,
    );
  }

  static Pitch fromFrequency(double freq) {
    if (freq <= 0) {
      return const Pitch(midi: 0, freq: 0, note: 'C', octave: 0, cents: 0);
    }
    final double midiValue = 69.0 + 12.0 * (log(freq / 440.0) / ln2);
    return fromMidi(midiValue);
  }

  String get fullNoteName => '$note$octave';
}

class StringTuning {
  final int stringIndex; // 0 = high E, 5 = low E
  final String note;
  final int midi;
  final double freq;
  final String gaugeName;

  const StringTuning({
    required this.stringIndex,
    required this.note,
    required this.midi,
    required this.freq,
    required this.gaugeName,
  });
}

class TuningPreset {
  final String id;
  final String name;
  final String description;
  final List<StringTuning> strings; // 0 = High e, 5 = Low E

  const TuningPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.strings,
  });

  static const TuningPreset standard = TuningPreset(
    id: 'standard',
    name: 'Standard (E A D G B E)',
    description: 'Universal standard guitar tuning',
    strings: [
      StringTuning(stringIndex: 0, note: 'E', midi: 64, freq: 329.63, gaugeName: '1st (High E)'),
      StringTuning(stringIndex: 1, note: 'B', midi: 59, freq: 246.94, gaugeName: '2nd (B)'),
      StringTuning(stringIndex: 2, note: 'G', midi: 55, freq: 196.00, gaugeName: '3rd (G)'),
      StringTuning(stringIndex: 3, note: 'D', midi: 50, freq: 146.83, gaugeName: '4th (D)'),
      StringTuning(stringIndex: 4, note: 'A', midi: 45, freq: 110.00, gaugeName: '5th (A)'),
      StringTuning(stringIndex: 5, note: 'E', midi: 40, freq: 82.41,  gaugeName: '6th (Low E)'),
    ],
  );

  static const TuningPreset dropD = TuningPreset(
    id: 'drop_d',
    name: 'Drop D (D A D G B E)',
    description: 'Low E tuned down one step to D',
    strings: [
      StringTuning(stringIndex: 0, note: 'E', midi: 64, freq: 329.63, gaugeName: '1st (High E)'),
      StringTuning(stringIndex: 1, note: 'B', midi: 59, freq: 246.94, gaugeName: '2nd (B)'),
      StringTuning(stringIndex: 2, note: 'G', midi: 55, freq: 196.00, gaugeName: '3rd (G)'),
      StringTuning(stringIndex: 3, note: 'D', midi: 50, freq: 146.83, gaugeName: '4th (D)'),
      StringTuning(stringIndex: 4, note: 'A', midi: 45, freq: 110.00, gaugeName: '5th (A)'),
      StringTuning(stringIndex: 5, note: 'D', midi: 38, freq: 73.42,  gaugeName: '6th (Low D)'),
    ],
  );

  static const TuningPreset dadgad = TuningPreset(
    id: 'dadgad',
    name: 'DADGAD (Celtic)',
    description: 'Rich modal tuning popular in folk and fingerstyle',
    strings: [
      StringTuning(stringIndex: 0, note: 'D', midi: 62, freq: 293.66, gaugeName: '1st (D)'),
      StringTuning(stringIndex: 1, note: 'A', midi: 57, freq: 220.00, gaugeName: '2nd (A)'),
      StringTuning(stringIndex: 2, note: 'G', midi: 55, freq: 196.00, gaugeName: '3rd (G)'),
      StringTuning(stringIndex: 3, note: 'D', midi: 50, freq: 146.83, gaugeName: '4th (D)'),
      StringTuning(stringIndex: 4, note: 'A', midi: 45, freq: 110.00, gaugeName: '5th (A)'),
      StringTuning(stringIndex: 5, note: 'D', midi: 38, freq: 73.42,  gaugeName: '6th (Low D)'),
    ],
  );

  static const TuningPreset halfStepDown = TuningPreset(
    id: 'half_step_down',
    name: 'Eb Standard (Eb Ab Db Gb Bb Eb)',
    description: 'Hendrix / SRV tuning down half step',
    strings: [
      StringTuning(stringIndex: 0, note: 'Eb', midi: 63, freq: 311.13, gaugeName: '1st (Eb)'),
      StringTuning(stringIndex: 1, note: 'Bb', midi: 58, freq: 233.08, gaugeName: '2nd (Bb)'),
      StringTuning(stringIndex: 2, note: 'Gb', midi: 54, freq: 185.00, gaugeName: '3rd (Gb)'),
      StringTuning(stringIndex: 3, note: 'Db', midi: 49, freq: 138.59, gaugeName: '4th (Db)'),
      StringTuning(stringIndex: 4, note: 'Ab', midi: 44, freq: 103.83, gaugeName: '5th (Ab)'),
      StringTuning(stringIndex: 5, note: 'Eb', midi: 39, freq: 77.78,  gaugeName: '6th (Low Eb)'),
    ],
  );

  static const List<TuningPreset> presets = [standard, dropD, dadgad, halfStepDown];
}

class ChordVoicing {
  final String name; // e.g. "Open", "Barre-E", "Barre-A", "Root 5"
  /// 6 strings: index 0 is Low E (string 6), index 5 is High E (string 1).
  /// null or -1 = muted (X), 0 = open (O), 1..24 = fret number
  final List<int?> frets;
  /// Finger numbers corresponding to frets (1=index, 2=middle, 3=ring, 4=pinky, null=open/muted)
  final List<int?>? fingers;
  final int? barreFret;
  final String difficulty;

  const ChordVoicing({
    required this.name,
    required this.frets,
    this.fingers,
    this.barreFret,
    this.difficulty = 'beginner',
  });

  /// Returns frets ordered low E (idx 0) to high e (idx 5)
  List<int?> get lowToHighFrets => frets;

  /// Returns frets ordered high e (idx 0) to low E (idx 5)
  List<int?> get highToLowFrets => frets.reversed.toList();
}

class ChordDefinition {
  final String root;
  final String quality; // 'Major', 'Minor', '7', 'maj7', 'm7', 'sus2', 'sus4', '5', 'dim', 'aug'
  final String name;
  final String formula;
  final List<int> intervals;
  final List<String> notes;
  final List<ChordVoicing> voicings;

  const ChordDefinition({
    required this.root,
    required this.quality,
    required this.name,
    required this.formula,
    required this.intervals,
    required this.notes,
    required this.voicings,
  });

  ChordVoicing get primaryVoicing =>
      voicings.isNotEmpty ? voicings.first : const ChordVoicing(name: 'Open', frets: [null, null, null, null, null, null]);
}

enum DetectionFreshness { fresh, held, none }
enum TunerVerdict { inTune, flat, sharp, unknown }

class DetectionResult {
  final String? chordName;
  final Pitch? detectedPitch;
  final double confidence; // 0.0 to 1.0
  final DetectionFreshness freshness;
  final TunerVerdict tunerVerdict;
  final double signalLevelDb;
  final List<double> chroma; // 12-element pitch class profile
  final DateTime timestamp;

  const DetectionResult({
    this.chordName,
    this.detectedPitch,
    this.confidence = 0.0,
    this.freshness = DetectionFreshness.none,
    this.tunerVerdict = TunerVerdict.unknown,
    this.signalLevelDb = -100.0,
    this.chroma = const [],
    required this.timestamp,
  });

  bool get hasChord => chordName != null && chordName!.isNotEmpty && confidence >= 0.55;
  bool get hasNote => detectedPitch != null && confidence >= 0.70;
}
