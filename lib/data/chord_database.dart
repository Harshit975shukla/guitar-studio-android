import '../models/music_models.dart';

class ChordDatabase {
  static final List<ChordDefinition> _allChords = [];

  static List<ChordDefinition> get allChords {
    if (_allChords.isEmpty) {
      _initChords();
    }
    return _allChords;
  }

  static ChordDefinition? findChord(String name) {
    final query = name.trim().replaceAll('♯', '#').replaceAll('♭', 'b');
    return allChords.cast<ChordDefinition?>().firstWhere(
      (c) => c?.name.toLowerCase() == query.toLowerCase(),
      orElse: () => null,
    );
  }

  static List<ChordDefinition> search(String query) {
    if (query.isEmpty) return allChords;
    final q = query.toLowerCase().trim();
    return allChords.where((c) => c.name.toLowerCase().contains(q) || c.root.toLowerCase() == q).toList();
  }

  static void _initChords() {
    _allChords.clear();
    _allChords.addAll([
      // C Chords
      const ChordDefinition(
        root: 'C', quality: 'Major', name: 'C', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['C', 'E', 'G'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 3, 2, 0, 1, 0], fingers: [null, 3, 2, null, 1, null]),
          ChordVoicing(name: 'Barre (8th fret)', frets: [8, 10, 10, 9, 8, 8], barreFret: 8, difficulty: 'intermediate'),
          ChordVoicing(name: 'Barre (3rd fret)', frets: [null, 3, 5, 5, 5, 3], barreFret: 3, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: 'Minor', name: 'Cm', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['C', 'Eb', 'G'],
        voicings: [
          ChordVoicing(name: 'Barre (3rd fret)', frets: [null, 3, 5, 5, 4, 3], barreFret: 3, difficulty: 'intermediate'),
          ChordVoicing(name: 'Barre (8th fret)', frets: [8, 10, 10, 8, 8, 8], barreFret: 8, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: '7', name: 'C7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['C', 'E', 'G', 'Bb'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 3, 2, 3, 1, 0], fingers: [null, 3, 2, 4, 1, null]),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: 'maj7', name: 'Cmaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['C', 'E', 'G', 'B'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 3, 2, 0, 0, 0], fingers: [null, 3, 2, null, null, null]),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: 'm7', name: 'Cm7', formula: '1 - b3 - 5 - b7',
        intervals: [0, 3, 7, 10], notes: ['C', 'Eb', 'G', 'Bb'],
        voicings: [
          ChordVoicing(name: 'Barre (3rd fret)', frets: [null, 3, 5, 3, 4, 3], barreFret: 3, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: 'sus4', name: 'Csus4', formula: '1 - 4 - 5',
        intervals: [0, 5, 7], notes: ['C', 'F', 'G'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 3, 3, 0, 1, 1], fingers: [null, 3, 4, null, 1, 1]),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: 'add9', name: 'Cadd9', formula: '1 - 3 - 5 - 9',
        intervals: [0, 4, 7, 14], notes: ['C', 'E', 'G', 'D'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 3, 2, 0, 3, 0], fingers: [null, 2, 1, null, 3, null]),
        ],
      ),
      const ChordDefinition(
        root: 'C', quality: '5', name: 'C5', formula: '1 - 5',
        intervals: [0, 7], notes: ['C', 'G'],
        voicings: [
          ChordVoicing(name: 'Power Chord', frets: [null, 3, 5, 5, null, null], fingers: [null, 1, 3, 4, null, null]),
        ],
      ),

      // D Chords
      const ChordDefinition(
        root: 'D', quality: 'Major', name: 'D', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['D', 'F#', 'A'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 3, 2], fingers: [null, null, null, 1, 3, 2]),
          ChordVoicing(name: 'Barre (5th fret)', frets: [null, 5, 7, 7, 7, 5], barreFret: 5, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: 'Minor', name: 'Dm', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['D', 'F', 'A'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 3, 1], fingers: [null, null, null, 2, 3, 1]),
          ChordVoicing(name: 'Barre (5th fret)', frets: [null, 5, 7, 7, 6, 5], barreFret: 5, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: '7', name: 'D7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['D', 'F#', 'A', 'C'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 1, 2], fingers: [null, null, null, 2, 1, 3]),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: 'maj7', name: 'Dmaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['D', 'F#', 'A', 'C#'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 2, 2], fingers: [null, null, null, 1, 1, 1], barreFret: 2),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: 'm7', name: 'Dm7', formula: '1 - b3 - 5 - b7',
        intervals: [0, 3, 7, 10], notes: ['D', 'F', 'A', 'C'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 1, 1], fingers: [null, null, null, 2, 1, 1]),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: 'sus2', name: 'Dsus2', formula: '1 - 2 - 5',
        intervals: [0, 2, 7], notes: ['D', 'E', 'A'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 3, 0], fingers: [null, null, null, 1, 3, null]),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: 'sus4', name: 'Dsus4', formula: '1 - 4 - 5',
        intervals: [0, 5, 7], notes: ['D', 'G', 'A'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, null, 0, 2, 3, 3], fingers: [null, null, null, 1, 2, 3]),
        ],
      ),
      const ChordDefinition(
        root: 'D', quality: '5', name: 'D5', formula: '1 - 5',
        intervals: [0, 7], notes: ['D', 'A'],
        voicings: [
          ChordVoicing(name: 'Power Chord', frets: [null, 5, 7, 7, null, null], fingers: [null, 1, 3, 4, null, null]),
        ],
      ),

      // E Chords
      const ChordDefinition(
        root: 'E', quality: 'Major', name: 'E', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['E', 'G#', 'B'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 2, 1, 0, 0], fingers: [null, 2, 3, 1, null, null]),
          ChordVoicing(name: 'Barre (7th fret)', frets: [null, 7, 9, 9, 9, 7], barreFret: 7, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: 'Minor', name: 'Em', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['E', 'G', 'B'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 2, 0, 0, 0], fingers: [null, 2, 3, null, null, null]),
          ChordVoicing(name: 'Barre (7th fret)', frets: [null, 7, 9, 9, 8, 7], barreFret: 7, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: '7', name: 'E7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['E', 'G#', 'B', 'D'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 0, 1, 0, 0], fingers: [null, 2, null, 1, null, null]),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: 'maj7', name: 'Emaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['E', 'G#', 'B', 'D#'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 1, 1, 0, 0], fingers: [null, 3, 1, 2, null, null]),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: 'm7', name: 'Em7', formula: '1 - b3 - 5 - b7',
        intervals: [0, 3, 7, 10], notes: ['E', 'G', 'B', 'D'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 0, 0, 0, 0], fingers: [null, 1, null, null, null, null]),
          ChordVoicing(name: 'Open (4-finger)', frets: [0, 2, 2, 0, 3, 3], fingers: [null, 1, 2, null, 3, 4]),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: 'sus4', name: 'Esus4', formula: '1 - 4 - 5',
        intervals: [0, 5, 7], notes: ['E', 'A', 'B'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [0, 2, 2, 2, 0, 0], fingers: [null, 1, 2, 3, null, null]),
        ],
      ),
      const ChordDefinition(
        root: 'E', quality: '5', name: 'E5', formula: '1 - 5',
        intervals: [0, 7], notes: ['E', 'B'],
        voicings: [
          ChordVoicing(name: 'Open Power', frets: [0, 2, 2, null, null, null], fingers: [null, 1, 2, null, null, null]),
          ChordVoicing(name: 'Barre Power', frets: [null, 7, 9, 9, null, null], fingers: [null, 1, 3, 4, null, null]),
        ],
      ),

      // F Chords
      const ChordDefinition(
        root: 'F', quality: 'Major', name: 'F', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['F', 'A', 'C'],
        voicings: [
          ChordVoicing(name: 'Full Barre (1st fret)', frets: [1, 3, 3, 2, 1, 1], barreFret: 1, difficulty: 'intermediate'),
          ChordVoicing(name: 'Easy Mini-Barre', frets: [null, null, 3, 2, 1, 1], fingers: [null, null, 3, 2, 1, 1]),
          ChordVoicing(name: 'Barre (8th fret)', frets: [null, 8, 10, 10, 10, 8], barreFret: 8, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'F', quality: 'Minor', name: 'Fm', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['F', 'Ab', 'C'],
        voicings: [
          ChordVoicing(name: 'Barre (1st fret)', frets: [1, 3, 3, 1, 1, 1], barreFret: 1, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'F', quality: '7', name: 'F7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['F', 'A', 'C', 'Eb'],
        voicings: [
          ChordVoicing(name: 'Barre (1st fret)', frets: [1, 3, 1, 2, 1, 1], barreFret: 1, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'F', quality: 'maj7', name: 'Fmaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['F', 'A', 'C', 'E'],
        voicings: [
          ChordVoicing(name: 'Easy Open', frets: [null, null, 3, 2, 1, 0], fingers: [null, null, 3, 2, 1, null]),
        ],
      ),

      // G Chords
      const ChordDefinition(
        root: 'G', quality: 'Major', name: 'G', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['G', 'B', 'D'],
        voicings: [
          ChordVoicing(name: 'Open (Rock)', frets: [3, 2, 0, 0, 3, 3], fingers: [2, 1, null, null, 3, 4]),
          ChordVoicing(name: 'Open (Folk)', frets: [3, 2, 0, 0, 0, 3], fingers: [3, 2, null, null, null, 4]),
          ChordVoicing(name: 'Barre (3rd fret)', frets: [3, 5, 5, 4, 3, 3], barreFret: 3, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'G', quality: 'Minor', name: 'Gm', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['G', 'Bb', 'D'],
        voicings: [
          ChordVoicing(name: 'Barre (3rd fret)', frets: [3, 5, 5, 3, 3, 3], barreFret: 3, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'G', quality: '7', name: 'G7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['G', 'B', 'D', 'F'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, null, null, null, 1]),
        ],
      ),
      const ChordDefinition(
        root: 'G', quality: 'maj7', name: 'Gmaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['G', 'B', 'D', 'F#'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [3, 2, 0, 0, 0, 2], fingers: [3, 2, null, null, null, 1]),
        ],
      ),
      const ChordDefinition(
        root: 'G', quality: 'sus4', name: 'Gsus4', formula: '1 - 4 - 5',
        intervals: [0, 5, 7], notes: ['G', 'C', 'D'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [3, 3, 0, 0, 1, 3], fingers: [2, 3, null, null, 1, 4]),
        ],
      ),
      const ChordDefinition(
        root: 'G', quality: '5', name: 'G5', formula: '1 - 5',
        intervals: [0, 7], notes: ['G', 'D'],
        voicings: [
          ChordVoicing(name: 'Power Chord', frets: [3, 5, 5, null, null, null], fingers: [1, 3, 4, null, null, null]),
        ],
      ),

      // A Chords
      const ChordDefinition(
        root: 'A', quality: 'Major', name: 'A', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['A', 'C#', 'E'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 2, 2, 0], fingers: [null, null, 1, 2, 3, null]),
          ChordVoicing(name: 'Barre (5th fret)', frets: [5, 7, 7, 6, 5, 5], barreFret: 5, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: 'Minor', name: 'Am', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['A', 'C', 'E'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 2, 1, 0], fingers: [null, null, 2, 3, 1, null]),
          ChordVoicing(name: 'Barre (5th fret)', frets: [5, 7, 7, 5, 5, 5], barreFret: 5, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: '7', name: 'A7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['A', 'C#', 'E', 'G'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 0, 2, 0], fingers: [null, null, 2, null, 3, null]),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: 'maj7', name: 'Amaj7', formula: '1 - 3 - 5 - 7',
        intervals: [0, 4, 7, 11], notes: ['A', 'C#', 'E', 'G#'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 1, 2, 0], fingers: [null, null, 2, 1, 3, null]),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: 'm7', name: 'Am7', formula: '1 - b3 - 5 - b7',
        intervals: [0, 3, 7, 10], notes: ['A', 'C', 'E', 'G'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 0, 1, 0], fingers: [null, null, 2, null, 1, null]),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: 'sus2', name: 'Asus2', formula: '1 - 2 - 5',
        intervals: [0, 2, 7], notes: ['A', 'B', 'E'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 2, 0, 0], fingers: [null, null, 1, 2, null, null]),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: 'sus4', name: 'Asus4', formula: '1 - 4 - 5',
        intervals: [0, 5, 7], notes: ['A', 'D', 'E'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 0, 2, 2, 3, 0], fingers: [null, null, 1, 2, 3, null]),
        ],
      ),
      const ChordDefinition(
        root: 'A', quality: '5', name: 'A5', formula: '1 - 5',
        intervals: [0, 7], notes: ['A', 'E'],
        voicings: [
          ChordVoicing(name: 'Open Power', frets: [null, 0, 2, 2, null, null], fingers: [null, null, 1, 2, null, null]),
          ChordVoicing(name: 'Barre Power', frets: [5, 7, 7, null, null, null], fingers: [1, 3, 4, null, null, null]),
        ],
      ),

      // B Chords
      const ChordDefinition(
        root: 'B', quality: 'Major', name: 'B', formula: '1 - 3 - 5',
        intervals: [0, 4, 7], notes: ['B', 'D#', 'F#'],
        voicings: [
          ChordVoicing(name: 'Barre (2nd fret)', frets: [null, 2, 4, 4, 4, 2], barreFret: 2, difficulty: 'intermediate'),
          ChordVoicing(name: 'Barre (7th fret)', frets: [7, 9, 9, 8, 7, 7], barreFret: 7, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'B', quality: 'Minor', name: 'Bm', formula: '1 - b3 - 5',
        intervals: [0, 3, 7], notes: ['B', 'D', 'F#'],
        voicings: [
          ChordVoicing(name: 'Barre (2nd fret)', frets: [null, 2, 4, 4, 3, 2], barreFret: 2, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'B', quality: '7', name: 'B7', formula: '1 - 3 - 5 - b7',
        intervals: [0, 4, 7, 10], notes: ['B', 'D#', 'F#', 'A'],
        voicings: [
          ChordVoicing(name: 'Open', frets: [null, 2, 1, 2, 0, 2], fingers: [null, 2, 1, 3, null, 4]),
        ],
      ),
      const ChordDefinition(
        root: 'B', quality: 'm7', name: 'Bm7', formula: '1 - b3 - 5 - b7',
        intervals: [0, 3, 7, 10], notes: ['B', 'D', 'F#', 'A'],
        voicings: [
          ChordVoicing(name: 'Barre (2nd fret)', frets: [null, 2, 4, 2, 3, 2], barreFret: 2, difficulty: 'intermediate'),
        ],
      ),
      const ChordDefinition(
        root: 'B', quality: 'dim', name: 'Bdim', formula: '1 - b3 - b5',
        intervals: [0, 3, 6], notes: ['B', 'D', 'F'],
        voicings: [
          ChordVoicing(name: 'Movable', frets: [null, 2, 3, 4, 3, null], fingers: [null, 1, 2, 4, 3, null]),
        ],
      ),
    ]);
  }
}
