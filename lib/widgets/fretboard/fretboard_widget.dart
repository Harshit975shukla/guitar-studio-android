import 'dart:math';
import 'package:flutter/material.dart';
import '../../audio/guitar_synthesizer.dart';
import '../../models/music_models.dart';
import 'fretboard_painter.dart';

class FretboardWidget extends StatefulWidget {
  final int totalFrets;
  final TuningPreset tuning;
  final List<int?> activeFrets; // Low E (idx 0) to High e (idx 5)
  final List<int?>? fingerNumbers;
  final String? rootNote;
  final Set<String>? highlightedNotes;
  final Pitch? detectedPitch;
  final bool isVertical;
  final Function(int stringIdx, int fret)? onFretTap;

  const FretboardWidget({
    super.key,
    this.totalFrets = 15,
    required this.tuning,
    required this.activeFrets,
    this.fingerNumbers,
    this.rootNote,
    this.highlightedNotes,
    this.detectedPitch,
    this.isVertical = false,
    this.onFretTap,
  });

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Map<int, double> _vibrations = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() {
          for (final k in _vibrations.keys) {
            _vibrations[k] = max(0.0, _vibrations[k]! * 0.92);
          }
        });
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerStringPluck(int stringIndex, int fret) {
    setState(() {
      _vibrations[stringIndex] = 1.0;
    });
    _animController.forward(from: 0.0);

    // Calculate frequency
    final double openFreq = widget.tuning.strings[stringIndex].freq;
    final double freq = openFreq * pow(2.0, fret / 12.0);
    GuitarSynthesizer().pluckString(freq);

    widget.onFretTap?.call(stringIndex, fret);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVertical) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double boardWidth = constraints.maxWidth;
          final double boardHeight = max(constraints.maxHeight, 460.0);
          return GestureDetector(
            onTapDown: (details) => _handleVerticalTap(details.localPosition, boardWidth, boardHeight),
            child: CustomPaint(
              size: Size(boardWidth, boardHeight),
              painter: FretboardPainter(
                totalFrets: widget.totalFrets,
                tuning: widget.tuning,
                activeFrets: widget.activeFrets,
                fingerNumbers: widget.fingerNumbers,
                rootNote: widget.rootNote,
                highlightedNotes: widget.highlightedNotes,
                detectedPitch: widget.detectedPitch,
                stringVibrations: _vibrations,
                isVertical: true,
              ),
            ),
          );
        },
      );
    }

    // Horizontal layout with scroll support for standard landscape/portrait view
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardHeight = 180.0;
        final double boardWidth = max(constraints.maxWidth, 720.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: GestureDetector(
            onTapDown: (details) => _handleHorizontalTap(details.localPosition, boardWidth, boardHeight),
            child: CustomPaint(
              size: Size(boardWidth, boardHeight),
              painter: FretboardPainter(
                totalFrets: widget.totalFrets,
                tuning: widget.tuning,
                activeFrets: widget.activeFrets,
                fingerNumbers: widget.fingerNumbers,
                rootNote: widget.rootNote,
                highlightedNotes: widget.highlightedNotes,
                detectedPitch: widget.detectedPitch,
                stringVibrations: _vibrations,
                isVertical: false,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleHorizontalTap(Offset pos, double w, double h) {
    // 6 Strings: String 0 is High E (top), String 5 is Low E (bottom)
    final double stringGap = h / 7.0;
    int tappedString = ((pos.dy - stringGap * 0.5) / stringGap).round().clamp(0, 5);

    // Nut width = 14
    int tappedFret = 0;
    if (pos.dx > 14.0) {
      final double playableWidth = w - 14.0;
      final double progress = (pos.dx - 14.0) / playableWidth;
      // Invert spacing formula roughly to get fret number
      tappedFret = ((-18.0 * log(1.0 - progress * (1.0 - pow(2.0, -widget.totalFrets / 18.0)))) / ln2).round().clamp(1, widget.totalFrets);
    }

    _triggerStringPluck(tappedString, tappedFret);
  }

  void _handleVerticalTap(Offset pos, double w, double h) {
    final double stringGap = w / 7.0;
    int tappedString = (5 - ((pos.dx - stringGap * 0.5) / stringGap).round()).clamp(0, 5);

    int tappedFret = 0;
    if (pos.dy > 14.0) {
      final double playableHeight = h - 14.0;
      final double progress = (pos.dy - 14.0) / playableHeight;
      tappedFret = ((-18.0 * log(1.0 - progress * (1.0 - pow(2.0, -widget.totalFrets / 18.0)))) / ln2).round().clamp(1, widget.totalFrets);
    }

    _triggerStringPluck(tappedString, tappedFret);
  }
}
