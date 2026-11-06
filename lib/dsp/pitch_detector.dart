import 'dart:math';
import '../models/music_models.dart';

class PitchDetector {
  static const double minFreq = 65.0;  // Guitar Low E2 is ~82.4 Hz, Drop D is ~73.4 Hz, C2 is 65 Hz
  static const double maxFreq = 1350.0; // High fret on High E4 is ~1320 Hz

  /// Estimates fundamental pitch from a raw PCM 16-bit or Float32 audio buffer.
  /// Uses normalized autocorrelation with parabolic peak refinement.
  static Pitch? estimatePitch(List<double> buffer, int sampleRate) {
    if (buffer.length < 512 || sampleRate < 8000) return null;

    final int stride = max(1, (sampleRate / 24000.0).ceil());
    final double rate = sampleRate / stride;

    final int minLag = (rate / maxFreq).floor();
    final int maxLag = (rate / minFreq).ceil();

    final int count = min(buffer.length ~/ stride, 1024 + maxLag + 2);
    final int window = count - maxLag - 1;
    if (window < maxLag * 2) return null;

    final List<double> samples = List<double>.filled(count, 0.0);
    double mean = 0.0;
    final int start = buffer.length - count * stride;

    for (int i = 0; i < count; i++) {
      double val = 0.0;
      for (int j = 0; j < stride; j++) {
        val += buffer[start + i * stride + j] / stride;
      }
      samples[i] = val;
      mean += val;
    }
    mean /= count;

    final List<double> energies = List<double>.filled(count + 1, 0.0);
    for (int i = 0; i < count; i++) {
      samples[i] -= mean;
      energies[i + 1] = energies[i] + samples[i] * samples[i];
    }

    final double rms = sqrt(energies[count] / count);
    if (rms < 0.005) return null; // Noise gate

    final List<double> correlations = List<double>.filled(maxLag + 2, 0.0);
    final double firstEnergy = energies[window];

    for (int lag = 1; lag <= maxLag + 1; lag++) {
      double dot = 0.0;
      for (int i = 0; i < window; i++) {
        dot += samples[i] * samples[i + lag];
      }
      final double denom = max(1e-12, firstEnergy + energies[window + lag] - energies[lag]);
      correlations[lag] = 2.0 * dot / denom;
    }

    _RefinedPeak refinedPeak(int lag) {
      final double a = correlations[lag - 1];
      final double b = correlations[lag];
      final double c = correlations[lag + 1];
      final double denom = a - 2.0 * b + c;
      final double shift = (denom.abs() < 1e-9) ? 0.0 : max(-0.5, min(0.5, 0.5 * (a - c) / denom));
      final double strength = min(1.0, b - 0.25 * (a - c) * shift);
      return _RefinedPeak(shift, strength);
    }

    final List<int> candidates = [];
    bool negative = false;
    double bestStrength = 0.0;

    for (int lag = 1; lag <= maxLag; lag++) {
      if (correlations[lag] < 0) negative = true;
      if (negative &&
          lag >= minLag &&
          correlations[lag] > correlations[lag - 1] &&
          correlations[lag] >= correlations[lag + 1]) {
        candidates.add(lag);
        bestStrength = max(bestStrength, refinedPeak(lag).strength);
      }
    }

    if (bestStrength < 0.75) return null;

    int? chosenLag;
    for (final lag in candidates) {
      if (refinedPeak(lag).strength >= max(0.75, bestStrength * 0.96)) {
        chosenLag = lag;
        break;
      }
    }
    if (chosenLag == null) return null;

    final peak = refinedPeak(chosenLag);
    final double freq = rate / (chosenLag + peak.shift);
    if (freq < minFreq || freq > maxFreq) return null;

    return Pitch.fromFrequency(freq);
  }

  /// Calculates root mean square (RMS) energy in decibels (dB)
  static double computeRmsDb(List<double> buffer) {
    if (buffer.isEmpty) return -100.0;
    double sum = 0.0;
    for (final s in buffer) {
      sum += s * s;
    }
    final double rms = sqrt(sum / buffer.length);
    if (rms <= 1e-6) return -100.0;
    return 20.0 * (log(rms) / ln10);
  }
}

class _RefinedPeak {
  final double shift;
  final double strength;
  const _RefinedPeak(this.shift, this.strength);
}
