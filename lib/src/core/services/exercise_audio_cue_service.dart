import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String exerciseAudioEnabledKey = 'exercise_audio_cues_enabled';
const String exerciseAudioIntervalKey = 'exercise_audio_cues_interval_meters';

class DistanceCue {
  const DistanceCue({
    required this.distanceMeters,
    required this.splitDuration,
    required this.paceSecondsPerKm,
  });

  final int distanceMeters;
  final Duration splitDuration;
  final double paceSecondsPerKm;
}

class DistanceCueTracker {
  DistanceCueTracker({required this.intervalMeters});

  final int intervalMeters;
  int _lastMilestone = 0;
  Duration _lastCueElapsed = Duration.zero;

  DistanceCue? update({
    required double distanceMeters,
    required Duration elapsed,
  }) {
    if (intervalMeters <= 0 || distanceMeters < intervalMeters) return null;
    final milestone = (distanceMeters ~/ intervalMeters) * intervalMeters;
    if (milestone <= _lastMilestone) return null;

    final split = elapsed - _lastCueElapsed;
    final covered = milestone - _lastMilestone;
    _lastMilestone = milestone;
    _lastCueElapsed = elapsed;
    final pace = split.inMilliseconds / 1000 / (covered / 1000);
    return DistanceCue(
      distanceMeters: milestone,
      splitDuration: split,
      paceSecondsPerKm: pace,
    );
  }
}

class ExerciseAudioCueService {
  ExerciseAudioCueService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;
  bool _enabled = true;
  int _intervalMeters = 1000;
  DistanceCueTracker _tracker = DistanceCueTracker(intervalMeters: 1000);

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _enabled = preferences.getBool(exerciseAudioEnabledKey) ?? true;
    _intervalMeters = preferences.getInt(exerciseAudioIntervalKey) ?? 1000;
    _tracker = DistanceCueTracker(intervalMeters: _intervalMeters);
    await _flutterTts.setLanguage('es-MX');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1);
    await _flutterTts.setPitch(1);
    await _flutterTts.awaitSpeakCompletion(false);
  }

  Future<void> announceProgress({
    required double distanceMeters,
    required Duration elapsed,
  }) async {
    if (!_enabled) return;
    final cue = _tracker.update(
      distanceMeters: distanceMeters,
      elapsed: elapsed,
    );
    if (cue == null) return;

    final distanceText = cue.distanceMeters >= 1000
        ? '${_compactNumber(cue.distanceMeters / 1000)} kilómetros'
        : '${cue.distanceMeters} metros';
    final split = _durationText(cue.splitDuration);
    final pace = _paceText(cue.paceSecondsPerKm);
    await _flutterTts.speak(
      '$distanceText completados. Tiempo del tramo $split. Ritmo $pace por kilómetro.',
    );
  }

  Future<void> stop() => _flutterTts.stop();

  void reset() {
    _tracker = DistanceCueTracker(intervalMeters: _intervalMeters);
  }

  String _compactNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  String _durationText(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes == 0) return '$seconds segundos';
    return '$minutes minutos $seconds segundos';
  }

  String _paceText(double secondsPerKm) {
    if (!secondsPerKm.isFinite || secondsPerKm <= 0) return 'no disponible';
    final rounded = secondsPerKm.round();
    final minutes = rounded ~/ 60;
    final seconds = rounded.remainder(60);
    return '$minutes minutos $seconds segundos';
  }
}
