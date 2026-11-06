import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_models.dart';

class GuitarSynthesizer {
  static final GuitarSynthesizer _instance = GuitarSynthesizer._internal();
  factory GuitarSynthesizer() => _instance;
  GuitarSynthesizer._internal();

  final AudioPlayer _player = AudioPlayer();
  static const int kSampleRate = 22050; // Optimized sample rate for mobile low-latency PCM

  /// Synthesizes a plucked string sound using Karplus-Strong physical modeling
  /// and plays it immediately.
  Future<void> pluckString(double freq, {double durationSec = 2.0, double volume = 0.8}) async {
    if (freq <= 0) return;
    final Uint8List wavBytes = generatePluckWav(freq, durationSec: durationSec, volume: volume);
    await _player.stop();
    await _player.play(BytesSource(wavBytes));
  }

  /// Synthesizes a strum of a 6-string chord (low to high or high to low)
  Future<void> strumChord(List<int?> frets, TuningPreset tuning, {bool downstroke = true}) async {
    // Collect non-muted strings
    final List<double> freqs = [];
    final List<double> stringDelays = [];

    final List<int> stringIndices = downstroke ? [5, 4, 3, 2, 1, 0] : [0, 1, 2, 3, 4, 5];
    double delay = 0.0;

    for (final s in stringIndices) {
      final int? fret = frets[s];
      if (fret != null && fret >= 0) {
        final double openFreq = tuning.strings[s].freq;
        final double stringFreq = openFreq * pow(2.0, fret / 12.0);
        freqs.add(stringFreq);
        stringDelays.add(delay);
        delay += 0.028; // ~28ms strum delay per string
      }
    }

    if (freqs.isEmpty) return;
    final Uint8List wavBytes = generateStrumWav(freqs, stringDelays, totalDurationSec: 2.8);
    await _player.stop();
    await _player.play(BytesSource(wavBytes));
  }

  /// Plays a metronome click (tick or tock)
  Future<void> playClick({bool accent = false}) async {
    final Uint8List wavBytes = generateClickWav(accent: accent);
    await _player.play(BytesSource(wavBytes));
  }

  /// Karplus-Strong string synthesis generating standard 16-bit Mono WAV bytes
  static Uint8List generatePluckWav(double freq, {double durationSec = 2.0, double volume = 0.8}) {
    final int numSamples = (kSampleRate * durationSec).toInt();
    final int delayLength = max(2, (kSampleRate / freq).round());

    final Random rng = Random();
    // Excitation buffer (white noise burst)
    final List<double> delayLine = List<double>.generate(
      delayLength,
      (_) => (rng.nextDouble() * 2.0 - 1.0) * volume,
    );

    final Int16List pcmSamples = Int16List(numSamples);
    int delayIdx = 0;
    double prevSample = 0.0;
    const double decay = 0.993; // Acoustic string damping factor

    for (int i = 0; i < numSamples; i++) {
      final double current = delayLine[delayIdx];
      // Low-pass filter (averaging adjacent samples)
      final double nextVal = 0.5 * (current + prevSample) * decay;
      delayLine[delayIdx] = nextVal;
      prevSample = current;

      delayIdx = (delayIdx + 1) % delayLength;

      // Convert to 16-bit PCM integer
      final int intSample = (current.clamp(-1.0, 1.0) * 32767).toInt();
      pcmSamples[i] = intSample;
    }

    return _wrapPcmInWav(pcmSamples, kSampleRate);
  }

  /// Synthesizes multiple strings overlapping in a realistic strum
  static Uint8List generateStrumWav(
    List<double> freqs,
    List<double> delaysSec, {
    double totalDurationSec = 2.8,
  }) {
    final int numSamples = (kSampleRate * totalDurationSec).toInt();
    final Float32List mixBuffer = Float32List(numSamples);
    final Random rng = Random();

    for (int s = 0; s < freqs.length; s++) {
      final double freq = freqs[s];
      final int startSample = (delaysSec[s] * kSampleRate).toInt();
      final int delayLength = max(2, (kSampleRate / freq).round());

      final List<double> delayLine = List<double>.generate(
        delayLength,
        (_) => (rng.nextDouble() * 2.0 - 1.0) * 0.45,
      );

      int delayIdx = 0;
      double prev = 0.0;
      const double decay = 0.994;

      for (int i = startSample; i < numSamples; i++) {
        final double current = delayLine[delayIdx];
        final double nextVal = 0.5 * (current + prev) * decay;
        delayLine[delayIdx] = nextVal;
        prev = current;
        delayIdx = (delayIdx + 1) % delayLength;

        mixBuffer[i] += current;
      }
    }

    final Int16List pcmSamples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      pcmSamples[i] = (mixBuffer[i].clamp(-1.0, 1.0) * 32767).toInt();
    }

    return _wrapPcmInWav(pcmSamples, kSampleRate);
  }

  /// Generates a sharp woodblock/metronome click
  static Uint8List generateClickWav({bool accent = false}) {
    const double duration = 0.04; // 40ms click
    final int numSamples = (kSampleRate * duration).toInt();
    final Int16List pcm = Int16List(numSamples);
    final double freq = accent ? 2200.0 : 1400.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / kSampleRate;
      final double env = exp(-t * 90.0);
      final double sample = sin(2.0 * pi * freq * t) * env;
      pcm[i] = (sample * 32767).toInt();
    }

    return _wrapPcmInWav(pcm, kSampleRate);
  }

  /// Encodes raw 16-bit PCM buffer into standard canonical RIFF WAV container
  static Uint8List _wrapPcmInWav(Int16List pcmData, int sampleRate) {
    final int byteLength = pcmData.length * 2;
    final ByteData header = ByteData(44);

    // RIFF chunk
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, 36 + byteLength, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    header.setUint16(32, 2, Endian.little);  // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample (16)

    // data sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, byteLength, Endian.little);

    final Uint8List wav = Uint8List(44 + byteLength);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + byteLength, pcmData.buffer.asUint8List());

    return wav;
  }
}
