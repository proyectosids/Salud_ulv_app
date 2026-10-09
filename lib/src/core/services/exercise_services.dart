import 'dart:async';
import 'package:rxdart/rxdart.dart';

// DateTime? lastStepTime;

// double smoothMagnitude = 0.0;
// double magnitudeBaseline = 0.0;

// bool countStep({
//   required List<double> accelerometerData,
// }) {
//   const double smoothAlpha = 0.8;
//   const double baselineAlpha = 0.95;
//   const double dynamicThreshold = 1.0;

//   const int minStepIntervalMs = 350;
//   const int maxStepIntervalMs = 1000;

//   final x = accelerometerData[0];
//   final y = accelerometerData[1];
//   final z = accelerometerData[2];

//   // Magnitud del movimiento.
//   final magnitude = sqrt(
//     x * x +
//     y * y +
//     z * z,
//   );

//   // Suavizado.
//   smoothMagnitude =
//       smoothAlpha * smoothMagnitude +
//       (1 - smoothAlpha) * magnitude;

//   // Nivel normal del dispositivo.
//   magnitudeBaseline =
//       baselineAlpha * magnitudeBaseline +
//       (1 - baselineAlpha) * smoothMagnitude;

//   // Movimiento relativo al nivel normal.
//   final movementSignal =
//       smoothMagnitude - magnitudeBaseline;

//   final now = DateTime.now();

//   bool validInterval = true;

//   if (lastStepTime != null) {
//     final elapsedMs =
//         now.difference(lastStepTime!).inMilliseconds;

//     validInterval =
//         elapsedMs >= minStepIntervalMs &&
//         elapsedMs <= maxStepIntervalMs;
//   }

//   final isPeak =
//       movementSignal > dynamicThreshold;

//   final stepDetected =
//       isPeak && validInterval;

//   debugPrint(
//     'ACCEL '
//     'mag=${magnitude.toStringAsFixed(3)} '
//     'smooth=${smoothMagnitude.toStringAsFixed(3)} '
//     'baseline=${magnitudeBaseline.toStringAsFixed(3)} '
//     'signal=${movementSignal.toStringAsFixed(3)} '
//     'threshold=$dynamicThreshold '
//     'intervalValid=$validInterval '
//     'step=$stepDetected',
//   );

//   if (stepDetected) {
//     lastStepTime = now;
//     return true;
//   }

//   return false;
// }

// double smoothMagnitude = 0.0;
// double baseline = 0.0;

// DateTime lastStepTime =
//     DateTime.fromMillisecondsSinceEpoch(0);

// bool countStep({
//   required List<double> accelerometerData,
// }) {
//   const smoothAlpha = 0.8;
//   const baselineAlpha = 0.95;
//   const threshold = 0.8;
//   bool step = false;

//   final x = accelerometerData[0];
//   final y = accelerometerData[1];
//   final z = accelerometerData[2];

//   final magnitude = sqrt(
//     x * x +
//     y * y +
//     z * z,
//   );

//   // Suavizar señal
//   smoothMagnitude =
//       smoothAlpha * smoothMagnitude +
//       (1 - smoothAlpha) * magnitude;

//   // Aprender el nivel normal del teléfono
//   baseline =
//       baselineAlpha * baseline +
//       (1 - baselineAlpha) * smoothMagnitude;

//   // Cuánto sobresale la señal respecto al baseline
//   final signal = smoothMagnitude - baseline;

//   final now = DateTime.now();

//   final enoughTime =
//       now.difference(lastStepTime) >
//       const Duration(milliseconds: 300);

//   debugPrint(
//   'ACCEL '
//   'x=${x.toStringAsFixed(3)} '
//   'y=${y.toStringAsFixed(3)} '
//   'z=${z.toStringAsFixed(3)} '
//   'magnitude=${magnitude.toStringAsFixed(3)} '
//   'smooth=${smoothMagnitude.toStringAsFixed(3)} '
//   'threshold=$enoughTime '
//   'step=$step',
// );

//   if (signal > threshold && enoughTime) {
//     lastStepTime = now;
//     step = true;
//     return step;
//   }

//   return step;
// }

// Calculate calories
double calculateCalories({
  required Duration elapsed,
  required double weightKg,
  required double met,
}) {
  // Needs the divition
  final minutes = elapsed.inSeconds / 60.0;
  return (minutes * met * weightKg) / 200;
}

double calculateSpeed() {
  return 0.0;
}

// Average calculator
double avgCalculator(List<num> values) {
  if (values.isEmpty) return 0;

  num sum = 0;

  for (num x in values) {
    sum += x;
  }

  return (sum / values.length);
}

double calculateCaloriesBurned(Duration time, double met, double bodyWeight) {
  // Time needs to be in minutes for the standard MET formula
  final double minutes = time.inSeconds / 60.0;

  final double calories = (minutes * met * bodyWeight) / 200;

  return calories;
}

double maxValue(Iterable<double> values, {double fallback = 0}) {
  double? max;
  for (final v in values) {
    if (!v.isFinite) continue;
    if (max == null || v > max) max = v;
  }
  return max ?? fallback;
}

double calculateStepsPerMinute(int steps, Duration time) {
  final double minutes = time.inSeconds / 60.0;

  if (minutes <= 0) return 0.0;

  final double stepsPerMinute = steps / minutes;

  return stepsPerMinute;
}

double valueByTime(List<num> values, int timeInSeconds) {
  if (values.isEmpty) return 0.0;

  final total = values.fold<num>(0, (a, b) => a + b);
  final minutes = values.length / timeInSeconds;

  if (minutes == 0) return 0;

  return total / minutes;
}

double totalElevationGain(List<num> elevationDeltas) {
  if (elevationDeltas.isEmpty) return 0.0;

  return elevationDeltas
      .where((delta) => delta > 0)
      .fold<num>(0, (sum, d) => sum + d)
      .toDouble();
}

// Calculate cadence
double calculateCadence(int movementDelta, Duration duration) {
  if (duration.inSeconds <= 0 || movementDelta <= 0) {
    return 0;
  }

  return movementDelta / duration.inSeconds;
}

double calculatePace(Duration duration, double distanceMeters) {
  if (duration.inSeconds <= 0 || distanceMeters <= 0) return 0;

  final minutes = duration.inSeconds / 60;
  final km = distanceMeters / 1000;
  final pace = minutes / km;

  if (pace > 30 || pace < 2) return 0;

  return pace;
}

// Reductor of stream speed
Stream<T> streamSpeedReductor<T>(Stream<T> stream, int pMilliseconds) {
  return stream.throttleTime(Duration(milliseconds: pMilliseconds));
}

// General timer for exercises
class ExerciseTimer {
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _isPaused = true;

  final _controller = StreamController<Duration>.broadcast();
  Stream<Duration> get stream => _controller.stream;

  Duration get elapsed => _elapsed;
  bool get isPaused => _isPaused;

  void start() {
    _elapsed = Duration.zero;
    _isPaused = false;
    _run();
  }

  void pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _run();
  }

  void stop() {
    _isPaused = true;
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    _elapsed = Duration.zero;
    _isPaused = true;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  void _run() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _controller.add(_elapsed);
    });
  }
}
