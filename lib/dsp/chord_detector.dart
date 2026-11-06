import 'dart:math';
import '../models/music_models.dart';

class ChordDetector {
  static const int kFftSize = 2048;
  static const int kStrumPatienceMs = 190;
  static const int kStrumCaptureWindowMs = 320;

  // Precomputed Hann window
  static final List<double> _hannWindow = List<double>.generate(
    kFftSize,
    (i) => 0.5 * (1.0 - cos(2.0 * pi * i / (kFftSize - 1))),
  );

  // Core Chord Templates from guitar-chord-studio-v2 engine
  static const Map<String, List<double>> kTemplates = {
    '': [1.3, -0.6, -0.3, -0.7, 1.1, -0.4, -0.6, 1.0, -0.6, -0.4, -0.5, -0.05], // Major
    'm': [1.3, -0.6, -0.3, 1.1, -0.7, -0.4, -0.6, 1.0, -0.4, -0.5, -0.05, -0.5], // Minor
    '7': [1.2, -0.5, -0.3, -0.6, 1.0, -0.4, -0.5, 0.9, -0.5, -0.4, 0.9, -0.5], // Dominant 7th
    'maj7': [1.2, -0.5, -0.3, -0.6, 1.0, -0.4, -0.5, 0.9, -0.5, -0.4, -0.5, 0.9], // Major 7th
    'm7': [1.2, -0.5, -0.3, 1.0, -0.6, -0.4, -0.5, 0.9, -0.5, -0.4, 0.9, -0.5], // Minor 7th
    'sus4': [1.3, -0.5, -0.3, -0.6, -0.6, 1.1, -0.5, 1.0, -0.5, -0.4, -0.4, -0.5], // Sus4
    'sus2': [1.3, -0.5, 1.1, -0.6, -0.6, -0.4, -0.5, 1.0, -0.5, -0.4, -0.4, -0.5], // Sus2
    '5': [1.4, -0.5, -0.4, -0.5, -0.5, -0.4, -0.5, 1.2, -0.5, -0.4, -0.4, -0.5], // Power chord
    'dim': [1.2, -0.5, -0.4, 1.1, -0.6, -0.4, 1.0, -0.6, -0.5, -0.4, -0.4, -0.5], // Diminished
    'aug': [1.2, -0.5, -0.4, -0.6, 1.1, -0.4, -0.5, -0.6, 1.0, -0.4, -0.4, -0.5], // Augmented
  };

  // State machine variables
  int _strumStartTime = 0;
  bool _inStrumWindow = false;
  String? _lastConfirmedChord;
  DateTime _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);
  final List<List<double>> _strumChromas = [];

  /// Detects chord and returns comprehensive DetectionResult
  DetectionResult processFrame(List<double> buffer, int sampleRate, double rmsDb) {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Check for silence / noise gate
    if (rmsDb < -45.0) {
      if (nowMs - _lastDetectionTime.millisecondsSinceEpoch > 3000) {
        _lastConfirmedChord = null;
      }
      return DetectionResult(
        chordName: _lastConfirmedChord,
        confidence: 0.0,
        freshness: _lastConfirmedChord != null ? DetectionFreshness.held : DetectionFreshness.none,
        signalLevelDb: rmsDb,
        chroma: List.filled(12, 0.0),
        timestamp: now,
      );
    }

    // Compute 12-chroma vector using FFT
    final List<double> chroma = _computeChroma(buffer, sampleRate);

    // Strum attack detection
    if (!_inStrumWindow) {
      _inStrumWindow = true;
      _strumStartTime = nowMs;
      _strumChromas.clear();
    }

    _strumChromas.add(chroma);
    final elapsed = nowMs - _strumStartTime;

    // Average chroma in window
    final List<double> avgChroma = List.filled(12, 0.0);
    for (final c in _strumChromas) {
      for (int i = 0; i < 12; i++) {
        avgChroma[i] += c[i];
      }
    }
    for (int i = 0; i < 12; i++) {
      avgChroma[i] /= max(1, _strumChromas.length);
    }

    // Match against chord templates
    _ChordMatch bestMatch = _findBestChordMatch(avgChroma);

    if (elapsed >= kStrumPatienceMs && elapsed <= kStrumCaptureWindowMs && bestMatch.score >= 0.55) {
      _lastConfirmedChord = bestMatch.name;
      _lastDetectionTime = now;
      if (elapsed >= kStrumCaptureWindowMs) {
        _inStrumWindow = false;
      }
      return DetectionResult(
        chordName: bestMatch.name,
        confidence: min(1.0, bestMatch.score),
        freshness: DetectionFreshness.fresh,
        signalLevelDb: rmsDb,
        chroma: avgChroma,
        timestamp: now,
      );
    } else if (elapsed > kStrumCaptureWindowMs) {
      _inStrumWindow = false;
    }

    return DetectionResult(
      chordName: _lastConfirmedChord ?? bestMatch.name,
      confidence: bestMatch.score,
      freshness: _lastConfirmedChord != null ? DetectionFreshness.held : DetectionFreshness.none,
      signalLevelDb: rmsDb,
      chroma: avgChroma,
      timestamp: now,
    );
  }

  static _ChordMatch _findBestChordMatch(List<double> chroma) {
    String bestName = '';
    double bestScore = -100.0;

    for (int root = 0; root < 12; root++) {
      final String rootName = kNoteNames[root];
      for (final entry in kTemplates.entries) {
        final String qualitySuffix = entry.key;
        final List<double> weights = entry.value;

        double dot = 0.0;
        for (int i = 0; i < 12; i++) {
          final int chromaIdx = (root + i) % 12;
          dot += chroma[chromaIdx] * weights[i];
        }

        // Normalize score roughly between 0.0 and 1.0
        final double score = dot / 2.5;
        if (score > bestScore) {
          bestScore = score;
          bestName = '$rootName$qualitySuffix';
        }
      }
    }

    return _ChordMatch(bestName, max(0.0, bestScore));
  }

  /// Calculates a 12-element Pitch Class Profile (Chroma) from audio buffer
  static List<double> _computeChroma(List<double> buffer, int sampleRate) {
    final List<double> re = List<double>.filled(kFftSize, 0.0);
    final List<double> im = List<double>.filled(kFftSize, 0.0);

    final int len = min(buffer.length, kFftSize);
    for (int i = 0; i < len; i++) {
      re[i] = buffer[i] * _hannWindow[i];
    }

    // In-place Cooley-Tukey FFT
    _fft(re, im);

    final List<double> chroma = List<double>.filled(12, 0.0);
    final double binWidth = sampleRate / kFftSize;

    // Accumulate spectral magnitude across guitar note frequencies (MIDI 36 to 84: 65 Hz to 1050 Hz)
    for (int midi = 36; midi <= 84; midi++) {
      final double freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0);
      final int bin = (freq / binWidth).round();
      if (bin >= 1 && bin < kFftSize ~/ 2) {
        final double mag = sqrt(re[bin] * re[bin] + im[bin] * im[bin]);
        final int pc = midi % 12;
        // Compensate for bass rolloff with frequency weight
        chroma[pc] += mag * sqrt(350.0 / freq);
      }
    }

    // Normalize chroma vector
    double maxVal = 0.0;
    for (final val in chroma) {
      if (val > maxVal) maxVal = val;
    }
    if (maxVal > 0.0) {
      for (int i = 0; i < 12; i++) {
        chroma[i] = sqrt(chroma[i] / maxVal);
      }
    }

    return chroma;
  }

  /// Radix-2 in-place Cooley-Tukey FFT
  static void _fft(List<double> re, List<double> im) {
    final int n = re.length;
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final double tr = re[i]; re[i] = re[j]; re[j] = tr;
        final double ti = im[i]; im[i] = im[j]; im[j] = ti;
      }
      int k = n ~/ 2;
      while (k <= j) {
        j -= k;
        k ~/= 2;
      }
      j += k;
    }

    for (int len = 2; len <= n; len <<= 1) {
      final double angle = -2.0 * pi / len;
      final double wlenRe = cos(angle);
      final double wlenIm = sin(angle);
      for (int i = 0; i < n; i += len) {
        double wRe = 1.0;
        double wIm = 0.0;
        for (int k = 0; k < len ~/ 2; k++) {
          final int u = i + k;
          final int v = i + k + len ~/ 2;
          final double vr = re[v] * wRe - im[v] * wIm;
          final double vi = re[v] * wIm + im[v] * wRe;
          re[v] = re[u] - vr;
          im[v] = im[u] - vi;
          re[u] += vr;
          im[u] += vi;
          final double nextWre = wRe * wlenRe - wIm * wlenIm;
          wIm = wRe * wlenIm + wIm * wlenRe;
          wRe = nextWre;
        }
      }
    }
  }
}

class _ChordMatch {
  final String name;
  final double score;
  const _ChordMatch(this.name, this.score);
}
