import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/music_models.dart';

class TunerMeter extends StatelessWidget {
  final Pitch? pitch;
  final String targetNote;
  final double targetFreq;

  const TunerMeter({
    super.key,
    this.pitch,
    required this.targetNote,
    required this.targetFreq,
  });

  @override
  Widget build(BuildContext context) {
    final int cents = pitch?.cents ?? 0;
    final bool hasSignal = pitch != null && pitch!.freq > 0;
    final bool inTune = hasSignal && cents.abs() <= 5;
    final bool isFlat = hasSignal && cents < -5;
    final bool isSharp = hasSignal && cents > 5;

    final Color statusColor = !hasSignal
        ? const Color(0xFF64748B)
        : (inTune
            ? AppTheme.emerald
            : (cents.abs() < 20 ? AppTheme.gold : AppTheme.red));

    final String statusText = !hasSignal
        ? 'PLUCK A STRING'
        : (inTune
            ? 'PERFECT • IN TUNE'
            : (isFlat ? 'TUNE UP (FLAT)' : 'TUNE DOWN (SHARP)'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Pitch & Cent Display
        Container(
          width: 220,
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: CustomPaint(
            painter: _MeterArcPainter(
              cents: hasSignal ? cents.toDouble() : 0.0,
              meterColor: statusColor,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasSignal ? pitch!.note : targetNote,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      hasSignal
                          ? '${pitch!.freq.toStringAsFixed(1)} Hz (${cents >= 0 ? '+' : ''}$cents¢)'
                          : 'Target: ${targetFreq.toStringAsFixed(1)} Hz',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Status Banner Pill
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                inTune
                    ? Icons.check_circle
                    : (isFlat ? Icons.arrow_upward : (isSharp ? Icons.arrow_downward : Icons.graphic_eq)),
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeterArcPainter extends CustomPainter {
  final double cents; // -50 to +50
  final Color meterColor;

  const _MeterArcPainter({required this.cents, required this.meterColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2.0, h * 0.9);
    final double radius = min(w / 2.0, h) * 0.95;

    // Background track arc (-50 to +50 cents = -pi/3 to +pi/3 from top)
    const double startAngle = pi + pi / 6; // 210 degrees
    const double sweepAngle = 2 * pi / 3;  // 120 degrees

    final Paint trackPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    // Center In-Tune Notch (0 cents)
    final Paint notchPaint = Paint()
      ..color = AppTheme.emerald
      ..strokeWidth = 3.0;
    final double topAngle = -pi / 2;
    canvas.drawLine(
      Offset(center.dx + (radius - 12) * cos(topAngle), center.dy + (radius - 12) * sin(topAngle)),
      Offset(center.dx + (radius + 4) * cos(topAngle), center.dy + (radius + 4) * sin(topAngle)),
      notchPaint,
    );

    // Needle indicator
    final double clampedCents = cents.clamp(-50.0, 50.0);
    // Maps -50..+50 to -pi/3..+pi/3 around top (-pi/2)
    final double needleAngle = -pi / 2 + (clampedCents / 50.0) * (pi / 3);

    final Paint needlePaint = Paint()
      ..color = meterColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final Offset needleTip = Offset(
      center.dx + radius * cos(needleAngle),
      center.dy + radius * sin(needleAngle),
    );
    canvas.drawLine(center, needleTip, needlePaint);
    canvas.drawCircle(center, 5.0, Paint()..color = meterColor);
  }

  @override
  bool shouldRepaint(covariant _MeterArcPainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.meterColor != meterColor;
  }
}
