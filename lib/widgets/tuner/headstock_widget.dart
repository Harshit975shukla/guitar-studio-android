import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/music_models.dart';

class HeadstockWidget extends StatelessWidget {
  final TuningPreset tuning;
  final int? activeStringIndex; // 0=High E .. 5=Low E
  final Pitch? detectedPitch;
  final Function(int stringIdx)? onPegSelect;

  const HeadstockWidget({
    super.key,
    required this.tuning,
    this.activeStringIndex,
    this.detectedPitch,
    this.onPegSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Strings in standard order:
    // Left side pegs (Low to high bass): 6th (E2, idx 5), 5th (A2, idx 4), 4th (D3, idx 3)
    // Right side pegs (Treble to high): 3rd (G3, idx 2), 2nd (B3, idx 1), 1st (E4, idx 0)
    final leftStrings = [tuning.strings[5], tuning.strings[4], tuning.strings[3]];
    final rightStrings = [tuning.strings[2], tuning.strings[1], tuning.strings[0]];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Pegs (E, A, D)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: leftStrings.map((s) => _buildPeg(s, isLeft: true)).toList(),
          ),

          const SizedBox(width: 12),

          // Headstock Body Center
          CustomPaint(
            size: const Size(120, 260),
            painter: _HeadstockBodyPainter(),
            child: const SizedBox(
              width: 120,
              height: 260,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'GUITAR STUDIO',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Right Pegs (G, B, E)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: rightStrings.map((s) => _buildPeg(s, isLeft: false)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeg(StringTuning str, {required bool isLeft}) {
    final bool isSelected = activeStringIndex == str.stringIndex;
    final bool isDetectedString = detectedPitch != null &&
        (detectedPitch!.freq - str.freq).abs() < (str.freq * 0.12);

    final bool inTune = isDetectedString && detectedPitch!.cents.abs() <= 5;
    final Color ringColor = inTune
        ? AppTheme.emerald
        : (isSelected || isDetectedString ? AppTheme.gold : const Color(0xFF334155));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () => onPegSelect?.call(str.stringIndex),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceElevated : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ringColor,
              width: (isSelected || inTune) ? 2.5 : 1.2,
            ),
            boxShadow: (isSelected || inTune)
                ? [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeft) ...[
                Text(
                  str.note,
                  style: TextStyle(
                    color: ringColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${str.freq.toStringAsFixed(1)}Hz',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ] else ...[
                Text(
                  '${str.freq.toStringAsFixed(1)}Hz',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
                const SizedBox(width: 6),
                Text(
                  str.note,
                  style: TextStyle(
                    color: ringColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadstockBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Authentic flared guitar headstock outline
    final Path path = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.95, h * 0.25)
      ..quadraticBezierTo(w * 0.98, h * 0.05, w * 0.65, 0)
      ..quadraticBezierTo(w * 0.5, h * 0.08, w * 0.35, 0)
      ..quadraticBezierTo(w * 0.02, h * 0.05, w * 0.05, h * 0.25)
      ..close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF131A26), Color(0xFF0A0E17)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fill);

    final Paint border = Paint()
      ..color = AppTheme.goldDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
