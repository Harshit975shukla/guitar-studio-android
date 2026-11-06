class ScaleDefinition {
  final String id;
  final String name;
  final String description;
  final List<int> intervals; // semitones from root
  final List<String> degrees; // '1', 'b3', '4', etc.

  const ScaleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.intervals,
    required this.degrees,
  });
}

class ScalesDatabase {
  static const List<ScaleDefinition> allScales = [
    ScaleDefinition(
      id: 'minor_pentatonic',
      name: 'Minor Pentatonic',
      description: 'The foundation of rock, blues, and pop guitar solos',
      intervals: [0, 3, 5, 7, 10],
      degrees: ['1', 'b3', '4', '5', 'b7'],
    ),
    ScaleDefinition(
      id: 'major_pentatonic',
      name: 'Major Pentatonic',
      description: 'Sweet, uplifting melodic scale (country, southern rock)',
      intervals: [0, 2, 4, 7, 9],
      degrees: ['1', '2', '3', '5', '6'],
    ),
    ScaleDefinition(
      id: 'blues',
      name: 'Blues Scale',
      description: 'Minor pentatonic with the gritty "blue note" (b5)',
      intervals: [0, 3, 5, 6, 7, 10],
      degrees: ['1', 'b3', '4', 'b5', '5', 'b7'],
    ),
    ScaleDefinition(
      id: 'major',
      name: 'Major Scale (Ionian)',
      description: 'The standard 7-note parent scale for Western music',
      intervals: [0, 2, 4, 5, 7, 9, 11],
      degrees: ['1', '2', '3', '4', '5', '6', '7'],
    ),
    ScaleDefinition(
      id: 'natural_minor',
      name: 'Natural Minor (Aeolian)',
      description: 'Pure minor tonality with melancholic emotion',
      intervals: [0, 2, 3, 5, 7, 8, 10],
      degrees: ['1', '2', 'b3', '4', '5', 'b6', 'b7'],
    ),
    ScaleDefinition(
      id: 'dorian',
      name: 'Dorian Mode',
      description: 'Minor mode with a bright major 6th (Santana, Pink Floyd)',
      intervals: [0, 2, 3, 5, 7, 9, 10],
      degrees: ['1', '2', 'b3', '4', '5', '6', 'b7'],
    ),
    ScaleDefinition(
      id: 'mixolydian',
      name: 'Mixolydian Mode',
      description: 'Major scale with flat 7th (Grateful Dead, AC/DC)',
      intervals: [0, 2, 4, 5, 7, 9, 10],
      degrees: ['1', '2', '3', '4', '5', '6', 'b7'],
    ),
  ];

  static ScaleDefinition findById(String id) {
    return allScales.firstWhere((s) => s.id == id, orElse: () => allScales.first);
  }
}
