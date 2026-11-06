import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/music_models.dart';

class FretboardPainter extends CustomPainter {
  final int totalFrets;
  final TuningPreset tuning;
  final List<int?> activeFrets; // 6 strings (low E idx 0 to high e idx 5)
  final List<int?>? fingerNumbers; // 1-4, null
  final String? rootNote;
  final Set<String>? highlightedNotes; // for scale highlights
  final Pitch? detectedPitch; // live pitch from mic
  final Map<int, double> stringVibrations; // string index -> vibration amplitude (0.0 to 1.0)
  final bool isVertical;

  FretboardPainter({
    this.totalFrets = 15,
    required this.tuning,
    required this.activeFrets,
    this.fingerNumbers,
    this.rootNote,
    this.highlightedNotes,
    this.detectedPitch,
    required this.stringVibrations,
    this.isVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isVertical) {
      _paintVertical(canvas, size);
    } else {
      _paintHorizontal(canvas, size);
    }
  }

  void _paintHorizontal(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Fretboard body
    final Rect boardRect = Rect.fromLTWH(0, 0, w, h);
    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.rosewoodDark, AppTheme.rosewoodLight, AppTheme.rosewoodDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(boardRect);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(8)), woodPaint);

    // Nut (Fret 0)
    final double nutWidth = 14.0;
    final Paint nutPaint = Paint()..color = AppTheme.brassNut;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, nutWidth, h), const Radius.circular(3)),
      nutPaint,
    );

    // Frets spacing calculation (1 to totalFrets)
    final double playableWidth = w - nutWidth;
    final List<double> fretPositions = [nutWidth];
    for (int f = 1; f <= totalFrets; f++) {
      // Proportional guitar fret spacing: d = L * (1 - 2^(-f/17.817))
      final double progress = (1.0 - pow(2.0, -f / 18.0)) / (1.0 - pow(2.0, -totalFrets / 18.0));
      fretPositions.add(nutWidth + progress * playableWidth);
    }

    // Inlays (dots)
    final List<int> singleDotFrets = [3, 5, 7, 9, 15, 17, 19, 21];
    final Paint inlayPaint = Paint()..color = AppTheme.fretInlay.withValues(alpha: 0.65);

    for (int f = 1; f <= totalFrets; f++) {
      final double xMid = (fretPositions[f - 1] + fretPositions[f]) / 2.0;
      if (singleDotFrets.contains(f)) {
        canvas.drawCircle(Offset(xMid, h * 0.5), 5.0, inlayPaint);
      } else if (f == 12 || f == 24) {
        // Double dots at octave
        canvas.drawCircle(Offset(xMid, h * 0.32), 4.5, inlayPaint);
        canvas.drawCircle(Offset(xMid, h * 0.68), 4.5, inlayPaint);
      }
    }

    // Fret wires
    final Paint fretWirePaint = Paint()
      ..color = AppTheme.fretWire
      ..strokeWidth = 2.5;
    for (int f = 1; f <= totalFrets; f++) {
      canvas.drawLine(Offset(fretPositions[f], 0), Offset(fretPositions[f], h), fretWirePaint);
    }

    // 6 Strings (String 5 is Low E at bottom, String 0 is High e at top)
    final double stringGap = h / 7.0;
    for (int s = 0; s < 6; s++) {
      // Map string s: 0=High e (top), 5=Low E (bottom)
      final double y = stringGap * (s + 1);
      final double gaugeThickness = 1.0 + (5 - s) * 0.6; // Low E is thicker
      final Color stringColor = s >= 3 ? AppTheme.bronzeString : AppTheme.silverString;

      // Vibration wave effect
      final double vibAmp = stringVibrations[s] ?? 0.0;
      if (vibAmp > 0.01) {
        final Path vibPath = Path()..moveTo(0, y);
        const int steps = 20;
        for (int i = 1; i <= steps; i++) {
          final double px = (w / steps) * i;
          final double py = y + sin(i * 1.5) * vibAmp * 4.0;
          vibPath.lineTo(px, py);
        }
        final Paint vibPaint = Paint()
          ..color = AppTheme.goldLight.withValues(alpha: 0.7)
          ..strokeWidth = gaugeThickness + 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(vibPath, vibPaint);
      }

      final Paint stringPaint = Paint()
        ..color = stringColor
        ..strokeWidth = gaugeThickness;
      canvas.drawLine(Offset(0, y), Offset(w, y), stringPaint);

      // Draw Nut indicator (X for muted, O for open)
      final int? fretted = activeFrets[5 - s];
      if (fretted == null || fretted < 0) {
        _drawMutedCross(canvas, Offset(nutWidth * 0.5, y));
      } else if (fretted == 0) {
        _drawOpenCircle(canvas, Offset(nutWidth * 0.5, y));
      }
    }

    // Draw active note markers and scale highlights
    for (int s = 0; s < 6; s++) {
      final int stringIdx = 5 - s; // 0 = Low E, 5 = High E in model
      final double y = stringGap * (s + 1);
      final int openMidi = tuning.strings[s].midi;

      // 1. Scale highlights if provided
      if (highlightedNotes != null && highlightedNotes!.isNotEmpty) {
        for (int f = 1; f <= totalFrets; f++) {
          final int noteMidi = openMidi + f;
          final String noteName = kNoteNames[noteMidi % 12];
          if (highlightedNotes!.contains(noteName)) {
            final double xMid = (fretPositions[f - 1] + fretPositions[f]) / 2.0;
            final bool isRoot = rootNote == noteName;
            _drawNoteMarker(
              canvas,
              Offset(xMid, y),
              noteName,
              isRoot: isRoot,
              isScaleTone: true,
            );
          }
        }
      }

      // 2. Active frets for chord voicings
      final int? activeFret = activeFrets[stringIdx];
      if (activeFret != null && activeFret > 0 && activeFret <= totalFrets) {
        final double xMid = (fretPositions[activeFret - 1] + fretPositions[activeFret]) / 2.0;
        final int noteMidi = openMidi + activeFret;
        final String noteName = kNoteNames[noteMidi % 12];
        final bool isRoot = rootNote == noteName;
        final int? finger = fingerNumbers?[stringIdx];

        _drawNoteMarker(
          canvas,
          Offset(xMid, y),
          finger != null ? '$finger' : noteName,
          isRoot: isRoot,
          isDetected: false,
        );
      }

      // 3. Microphone live detected note
      if (detectedPitch != null) {
        for (int f = 0; f <= totalFrets; f++) {
          if (openMidi + f == detectedPitch!.midi) {
            final double xMid = f == 0 ? nutWidth * 0.5 : (fretPositions[f - 1] + fretPositions[f]) / 2.0;
            _drawNoteMarker(
              canvas,
              Offset(xMid, y),
              detectedPitch!.note,
              isRoot: false,
              isDetected: true,
            );
          }
        }
      }
    }
  }

  void _paintVertical(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background
    final Rect boardRect = Rect.fromLTWH(0, 0, w, h);
    final Paint woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.rosewoodDark, AppTheme.rosewoodLight, AppTheme.rosewoodDark],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(boardRect);
    canvas.drawRRect(RRect.fromRectAndRadius(boardRect, const Radius.circular(8)), woodPaint);

    // Nut at top
    final double nutHeight = 14.0;
    final Paint nutPaint = Paint()..color = AppTheme.brassNut;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, nutHeight), const Radius.circular(3)),
      nutPaint,
    );

    // Frets spacing downwards
    final double playableHeight = h - nutHeight;
    final List<double> fretPositions = [nutHeight];
    for (int f = 1; f <= totalFrets; f++) {
      final double progress = (1.0 - pow(2.0, -f / 18.0)) / (1.0 - pow(2.0, -totalFrets / 18.0));
      fretPositions.add(nutHeight + progress * playableHeight);
    }

    // Inlays
    final List<int> singleDotFrets = [3, 5, 7, 9, 15, 17, 19, 21];
    final Paint inlayPaint = Paint()..color = AppTheme.fretInlay.withValues(alpha: 0.65);
    for (int f = 1; f <= totalFrets; f++) {
      final double yMid = (fretPositions[f - 1] + fretPositions[f]) / 2.0;
      if (singleDotFrets.contains(f)) {
        canvas.drawCircle(Offset(w * 0.5, yMid), 5.0, inlayPaint);
      } else if (f == 12 || f == 24) {
        canvas.drawCircle(Offset(w * 0.32, yMid), 4.5, inlayPaint);
        canvas.drawCircle(Offset(w * 0.68, yMid), 4.5, inlayPaint);
      }
    }

    // Fret wires
    final Paint fretWirePaint = Paint()
      ..color = AppTheme.fretWire
      ..strokeWidth = 2.5;
    for (int f = 1; f <= totalFrets; f++) {
      canvas.drawLine(Offset(0, fretPositions[f]), Offset(w, fretPositions[f]), fretWirePaint);
    }

    // 6 Strings: Left (Low E, s=5) to Right (High E, s=0)
    final double stringGap = w / 7.0;
    for (int s = 0; s < 6; s++) {
      final double x = stringGap * (s + 1);
      final double gaugeThickness = 1.0 + s * 0.6; // String 0 on left (Low E)
      final Color stringColor = s <= 2 ? AppTheme.bronzeString : AppTheme.silverString;

      final Paint stringPaint = Paint()
        ..color = stringColor
        ..strokeWidth = gaugeThickness;
      canvas.drawLine(Offset(x, 0), Offset(x, h), stringPaint);

      // Nut indicators
      final int? fretted = activeFrets[s];
      if (fretted == null || fretted < 0) {
        _drawMutedCross(canvas, Offset(x, nutHeight * 0.5));
      } else if (fretted == 0) {
        _drawOpenCircle(canvas, Offset(x, nutHeight * 0.5));
      }

      // Fretted note markers
      if (fretted != null && fretted > 0 && fretted <= totalFrets) {
        final double yMid = (fretPositions[fretted - 1] + fretPositions[fretted]) / 2.0;
        final int noteMidi = tuning.strings[5 - s].midi + fretted;
        final String noteName = kNoteNames[noteMidi % 12];
        final bool isRoot = rootNote == noteName;
        final int? finger = fingerNumbers?[s];

        _drawNoteMarker(
          canvas,
          Offset(x, yMid),
          finger != null ? '$finger' : noteName,
          isRoot: isRoot,
        );
      }
    }
  }

  void _drawNoteMarker(
    Canvas canvas,
    Offset center,
    String text, {
    bool isRoot = false,
    bool isDetected = false,
    bool isScaleTone = false,
  }) {
    final double radius = isScaleTone ? 9.0 : 12.0;

    Color fillColor;
    Color textColor;

    if (isDetected) {
      fillColor = AppTheme.emerald;
      textColor = Colors.black;
      // Emerald Glow
      final Paint glowPaint = Paint()
        ..color = AppTheme.emerald.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius + 4, glowPaint);
    } else if (isRoot) {
      fillColor = AppTheme.gold;
      textColor = Colors.black;
      final Paint glowPaint = Paint()
        ..color = AppTheme.gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius + 3, glowPaint);
    } else if (isScaleTone) {
      fillColor = AppTheme.cyan.withValues(alpha: 0.85);
      textColor = Colors.black;
    } else {
      fillColor = const Color(0xFFFFF8E1); // Warm Cream
      textColor = Colors.black87;
    }

    final Paint circlePaint = Paint()..color = fillColor;
    canvas.drawCircle(center, radius, circlePaint);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: isScaleTone ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - tp.width / 2.0, center.dy - tp.height / 2.0));
  }

  void _drawMutedCross(Canvas canvas, Offset center) {
    final Paint p = Paint()
      ..color = AppTheme.red
      ..strokeWidth = 2.0;
    const double d = 4.0;
    canvas.drawLine(Offset(center.dx - d, center.dy - d), Offset(center.dx + d, center.dy + d), p);
    canvas.drawLine(Offset(center.dx + d, center.dy - d), Offset(center.dx - d, center.dy + d), p);
  }

  void _drawOpenCircle(Canvas canvas, Offset center) {
    final Paint p = Paint()
      ..color = AppTheme.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 4.5, p);
  }

  @override
  bool shouldRepaint(covariant FretboardPainter oldDelegate) {
    return true; // repaint on vibration, detection, or fret change
  }
}
