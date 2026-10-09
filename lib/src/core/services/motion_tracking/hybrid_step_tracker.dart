import 'dart:math' as math;

import '../../repositories/repos/sensors_repo.dart';
import 'location_track_filter.dart';

/// Reconciles independent step sources without adding duplicate observations.
///
/// Native and fallback values are alternative observations of the same walk:
/// they are selected by priority and never added together. GPS-derived steps
/// are used only when the device exposes no native pedometer and the software
/// accelerometer has not produced a usable count.
class HybridStepTracker {
  HybridStepTracker({
    this.minimumDistanceEvidence = 3,
    double defaultStepLengthMeters = 0.72,
  }) : _defaultStepLengthMeters = defaultStepLengthMeters,
       _stepLengthMeters = defaultStepLengthMeters;

  /// Common initial approximation for adult walking step length. This is only
  /// a fallback; native and accelerometer counts remain preferable.
  static const heightToStepLengthRatio = 0.413;

  static const minimumPlausibleStepLengthMeters = 0.45;
  static const maximumPlausibleStepLengthMeters = 0.95;
  static const counterDeliveryGrace = Duration(seconds: 12);
  static const detectorDeliveryGrace = Duration(seconds: 3);

  final double minimumDistanceEvidence;
  final double _defaultStepLengthMeters;
  double _stepLengthMeters;
  double? _heightCm;

  double get estimatedStepLengthMeters => _stepLengthMeters;

  void configureHeightCm(double? heightCm) {
    if (heightCm == null ||
        !heightCm.isFinite ||
        heightCm < 100 ||
        heightCm > 250) {
      _stepLengthMeters = _defaultStepLengthMeters;
      _heightCm = null;
      return;
    }

    _heightCm = heightCm;
    _stepLengthMeters = (heightCm / 100 * heightToStepLengthRatio).clamp(
      minimumPlausibleStepLengthMeters,
      maximumPlausibleStepLengthMeters,
    );
  }

  bool _platformAvailabilityKnown = false;
  bool _counterAvailable = false;
  bool _detectorAvailable = false;
  int _latestConfirmedSteps = 0;
  int _latestLiveSteps = 0;
  int _lastResolvedConfirmedSteps = 0;
  int _lastResolvedLiveSteps = 0;
  int _acceptedConfirmedSteps = 0;
  int _acceptedLiveSteps = 0;
  int _accelerometerSteps = 0;
  double _lastDistanceMeters = 0;
  double _distanceEstimatedSteps = 0;
  double _lastCalibrationDistanceMeters = 0;
  int _highestResolvedSteps = 0;
  DateTime? _lastMovingAt;
  bool _hasSessionCalibration = false;

  bool get usesNativeSensor =>
      _platformAvailabilityKnown && (_counterAvailable || _detectorAvailable);

  double get estimatedDistanceMeters =>
      _highestResolvedSteps * _stepLengthMeters;

  bool get hasSessionCalibration => _hasSessionCalibration;

  void configureCalibratedStepLengthMeters(double? meters) {
    if (meters == null ||
        !meters.isFinite ||
        meters < minimumPlausibleStepLengthMeters ||
        meters > maximumPlausibleStepLengthMeters) {
      return;
    }
    _stepLengthMeters = meters;
  }

  void updatePlatformReading(PlatformStepReading reading) {
    _platformAvailabilityKnown = true;
    _counterAvailable = reading.counterAvailable;
    _detectorAvailable = reading.detectorAvailable;
    if (reading.confirmedSteps >= _latestConfirmedSteps) {
      _latestConfirmedSteps = reading.confirmedSteps;
    }
    if (reading.liveSteps >= _latestLiveSteps) {
      _latestLiveSteps = reading.liveSteps;
    }
  }

  /// Advances the native baselines without counting the reading. This is used
  /// while an activity is paused so buffered platform events cannot appear as
  /// a jump when the session resumes.
  void discardPlatformReading(PlatformStepReading reading) {
    updatePlatformReading(reading);
    _lastResolvedConfirmedSteps = _latestConfirmedSteps;
    _lastResolvedLiveSteps = _latestLiveSteps;
  }

  void markPlatformUnavailable() {
    _platformAvailabilityKnown = true;
    _counterAvailable = false;
    _detectorAvailable = false;
  }

  void addAccelerometerSteps(int value) {
    if (value > 0) _accelerometerSteps += value;
  }

  int resolve({
    required double distanceMeters,
    required LocationMotionState motionState,
    double walkingSpeedMetersPerSecond = 0,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final validDistance = distanceMeters.isFinite && distanceMeters > 0
        ? distanceMeters
        : 0.0;
    final hasDistanceEvidence = validDistance >= minimumDistanceEvidence;
    if (motionState == LocationMotionState.moving) _lastMovingAt = now;

    // Convert only NEW, GPS-confirmed displacement into estimated steps. The
    // old implementation recalculated the entire route using distance/time;
    // when the user stopped, elapsed time kept growing, the inferred step
    // length shrank and the step total increased without new movement.
    final distanceDelta = validDistance - _lastDistanceMeters;
    if (distanceDelta > 0 && motionState == LocationMotionState.moving) {
      _distanceEstimatedSteps +=
          distanceDelta / _stepLengthForSpeed(walkingSpeedMetersPerSecond);
    }
    if (distanceDelta != 0) _lastDistanceMeters = validDistance;

    final sinceMovement = _lastMovingAt == null
        ? null
        : now.difference(_lastMovingAt!);
    final counterAllowed =
        motionState != LocationMotionState.stationary ||
        (sinceMovement != null && sinceMovement <= counterDeliveryGrace);
    final detectorAllowed =
        motionState != LocationMotionState.stationary ||
        (sinceMovement != null && sinceMovement <= detectorDeliveryGrace);

    // TYPE_STEP_COUNTER can arrive in batches several seconds late. A short
    // grace window accepts a legitimate final batch after stopping, while
    // later stationary deltas are consumed and cannot surface on resume.
    final confirmedDelta = _latestConfirmedSteps - _lastResolvedConfirmedSteps;
    if (confirmedDelta > 0 && counterAllowed) {
      _acceptedConfirmedSteps += confirmedDelta;
    }
    _lastResolvedConfirmedSteps = _latestConfirmedSteps;

    // TYPE_STEP_DETECTOR provides the responsive on-screen value. It remains
    // an alternative view of the native count, never an additional source.
    final liveDelta = _latestLiveSteps - _lastResolvedLiveSteps;
    if (liveDelta > 0 && detectorAllowed) {
      _acceptedLiveSteps += liveDelta;
    }
    _lastResolvedLiveSteps = _latestLiveSteps;

    _calibrateStepLength(validDistance, motionState);

    final distanceFloor = hasDistanceEvidence
        ? _distanceEstimatedSteps.floor()
        : 0;

    final nativeSteps = math.max(_acceptedConfirmedSteps, _acceptedLiveSteps);
    final fallbackSteps = _accelerometerSteps > 0
        ? _accelerometerSteps
        : distanceFloor;
    final resolved = usesNativeSensor ? nativeSteps : fallbackSteps;
    if (resolved > _highestResolvedSteps) _highestResolvedSteps = resolved;
    return _highestResolvedSteps;
  }

  void _calibrateStepLength(
    double distanceMeters,
    LocationMotionState motionState,
  ) {
    if (!_counterAvailable ||
        motionState != LocationMotionState.moving ||
        _acceptedConfirmedSteps < 100 ||
        distanceMeters < 80 ||
        distanceMeters - _lastCalibrationDistanceMeters < 100) {
      return;
    }

    _lastCalibrationDistanceMeters = distanceMeters;
    final observed = distanceMeters / _acceptedConfirmedSteps;
    if (observed < minimumPlausibleStepLengthMeters ||
        observed > maximumPlausibleStepLengthMeters) {
      return;
    }

    // Slow adaptation prevents one noisy GPS segment from replacing the
    // stature-based estimate. Calibration affects distance fallback only.
    _stepLengthMeters = (_stepLengthMeters * 0.85) + (observed * 0.15);
    _hasSessionCalibration = true;
  }

  /// Estimates step length using GPS speed and stature when both are known.
  /// The published model estimates a complete stride, so the result is
  /// divided by two to obtain the distance covered by one step.
  double _stepLengthForSpeed(double speedMetersPerSecond) {
    final heightCm = _heightCm;
    if (heightCm == null ||
        !speedMetersPerSecond.isFinite ||
        speedMetersPerSecond < 0.2) {
      return _stepLengthMeters;
    }

    final strideMeters =
        (0.55 * speedMetersPerSecond) + (0.005 * heightCm) - 0.222;
    return (strideMeters / 2).clamp(
      minimumPlausibleStepLengthMeters,
      maximumPlausibleStepLengthMeters,
    );
  }

  void reset() {
    _platformAvailabilityKnown = false;
    _counterAvailable = false;
    _detectorAvailable = false;
    _latestConfirmedSteps = 0;
    _latestLiveSteps = 0;
    _lastResolvedConfirmedSteps = 0;
    _lastResolvedLiveSteps = 0;
    _acceptedConfirmedSteps = 0;
    _acceptedLiveSteps = 0;
    _accelerometerSteps = 0;
    _lastDistanceMeters = 0;
    _distanceEstimatedSteps = 0;
    _lastCalibrationDistanceMeters = 0;
    _highestResolvedSteps = 0;
    _lastMovingAt = null;
    _hasSessionCalibration = false;
  }
}
