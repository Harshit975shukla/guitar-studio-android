import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../dsp/chord_detector.dart';
import '../dsp/pitch_detector.dart';
import '../models/music_models.dart';

class AudioInputService {
  static final AudioInputService _instance = AudioInputService._internal();
  factory AudioInputService() => _instance;
  AudioInputService._internal();

  static const EventChannel _eventChannel =
      EventChannel('com.leadingnote.guitar_studio/audio_record');

  StreamSubscription? _subscription;
  final StreamController<DetectionResult> _resultController =
      StreamController<DetectionResult>.broadcast();

  Stream<DetectionResult> get detectionStream => _resultController.stream;

  final ChordDetector _chordDetector = ChordDetector();
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<bool> startListening() async {
    if (_isListening) return true;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    try {
      _isListening = true;
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is List) {
            final List<double> samples = event.map((e) => (e as num).toDouble()).toList();
            _processAudioChunk(samples);
          }
        },
        onError: (dynamic error) {
          _isListening = false;
        },
      );
      return true;
    } catch (e) {
      _isListening = false;
      return false;
    }
  }

  void _processAudioChunk(List<double> buffer) {
    const int sampleRate = 22050;
    final double rmsDb = PitchDetector.computeRmsDb(buffer);
    final Pitch? pitch = PitchDetector.estimatePitch(buffer, sampleRate);
    final DetectionResult chordResult = _chordDetector.processFrame(buffer, sampleRate, rmsDb);

    TunerVerdict verdict = TunerVerdict.unknown;
    if (pitch != null) {
      if (pitch.cents.abs() <= 5) {
        verdict = TunerVerdict.inTune;
      } else if (pitch.cents < -5) {
        verdict = TunerVerdict.flat;
      } else {
        verdict = TunerVerdict.sharp;
      }
    }

    final combinedResult = DetectionResult(
      chordName: chordResult.chordName,
      detectedPitch: pitch,
      confidence: pitch != null ? 0.90 : chordResult.confidence,
      freshness: chordResult.freshness,
      tunerVerdict: verdict,
      signalLevelDb: rmsDb,
      chroma: chordResult.chroma,
      timestamp: DateTime.now(),
    );

    _resultController.add(combinedResult);
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _resultController.close();
  }
}
