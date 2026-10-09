import 'dart:math' as math;

enum LocationMotionState { unavailable, stationary, moving }

class LocationTrackPoint {
  const LocationTrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.reportedSpeed,
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
  final double reportedSpeed;
}

class LocationTrackUpdate {
  const LocationTrackUpdate({
    required this.accepted,
    required this.distanceDelta,
    required this.speed,
    required this.motionState,
  });

  final bool accepted;
  final double distanceDelta;
  final double speed;
  final LocationMotionState motionState;
}

/// Pure-Dart filter for noisy mobile location samples.
///
/// Distance is measured against the last accepted anchor instead of between
/// every GPS reading. This makes small stationary drifts accumulate against a
/// fixed point rather than becoming false travelled distance.
class LocationTrackFilter {
  LocationTrackFilter({
    required this.minimumDisplacement,
    required this.maximumAccuracy,
    required this.maximumSpeed,
    this.maximumNoiseRadius = 12,
    // GPS updates can be 10-20 seconds apart during a slow walk. Keep recent
    // confirmed displacement alive long enough for step candidates arriving
    // between two accepted fixes.
    this.movementHold = const Duration(seconds: 20),
    this.reliableFixLifetime = const Duration(seconds: 12),
  });

  final double minimumDisplacement;
  final double maximumAccuracy;
  final double maximumSpeed;
  final double maximumNoiseRadius;
  final Duration movementHold;
  final Duration reliableFixLifetime;

  LocationTrackPoint? _anchor;
  DateTime? _lastReliableFixAt;
  DateTime? _lastMovementAt;
  int _stationaryFixes = 0;
  double _distance = 0;
  double _speed = 0;
  double _elevationGain = 0;

  double get distance => _distance;
  double get speed => _speed;
  double get elevationGain => _elevationGain;

  bool hasReliableFixAt(DateTime now) {
    final lastFix = _lastReliableFixAt;
    return lastFix != null && now.difference(lastFix) <= reliableFixLifetime;
  }

  LocationMotionState motionStateAt(DateTime now) {
    if (!hasReliableFixAt(now)) return LocationMotionState.unavailable;
    final lastMovement = _lastMovementAt;
    if (lastMovement != null && now.difference(lastMovement) <= movementHold) {
      return LocationMotionState.moving;
    }
    return LocationMotionState.stationary;
  }

  LocationTrackUpdate update(LocationTrackPoint point) {
    if (!_isValid(point) || point.accuracy > maximumAccuracy) {
      return LocationTrackUpdate(
        accepted: false,
        distanceDelta: 0,
        speed: _speed,
        motionState: motionStateAt(point.timestamp),
      );
    }

    _lastReliableFixAt = point.timestamp;
    final anchor = _anchor;
    if (anchor == null) {
      _anchor = point;
      _speed = 0;
      return const LocationTrackUpdate(
        accepted: true,
        distanceDelta: 0,
        speed: 0,
        motionState: LocationMotionState.stationary,
      );
    }

    final elapsedSeconds =
        point.timestamp.difference(anchor.timestamp).inMilliseconds / 1000;
    if (elapsedSeconds <= 0) {
      return LocationTrackUpdate(
        accepted: false,
        distanceDelta: 0,
        speed: _speed,
        motionState: motionStateAt(point.timestamp),
      );
    }

    final delta = distanceBetween(anchor, point);
    final derivedSpeed = delta / elapsedSeconds;
    if (derivedSpeed > maximumSpeed) {
      return LocationTrackUpdate(
        accepted: false,
        distanceDelta: 0,
        speed: _speed,
        motionState: motionStateAt(point.timestamp),
      );
    }

    final noiseRadius = math.max(
      minimumDisplacement,
      math.min(maximumNoiseRadius, (anchor.accuracy + point.accuracy) * 0.35),
    );

    if (delta < noiseRadius) {
      _stationaryFixes++;
      if (_stationaryFixes >= 3) _lastMovementAt = null;
      _speed *= 0.55;
      if (_speed < 0.15) _speed = 0;
      return LocationTrackUpdate(
        accepted: false,
        distanceDelta: 0,
        speed: _speed,
        motionState: motionStateAt(point.timestamp),
      );
    }

    final reportedSpeed = point.reportedSpeed;
    final measuredSpeed =
        reportedSpeed.isFinite &&
            reportedSpeed >= 0 &&
            reportedSpeed <= maximumSpeed
        ? (reportedSpeed * 0.65) + (derivedSpeed * 0.35)
        : derivedSpeed;

    _distance += delta;
    _stationaryFixes = 0;
    _speed = (_speed * 0.35) + (measuredSpeed * 0.65);
    final altitudeDelta = point.altitude - anchor.altitude;
    if (altitudeDelta > math.max(1.5, noiseRadius * 0.5)) {
      _elevationGain += altitudeDelta;
    }
    _anchor = point;
    _lastMovementAt = point.timestamp;

    return LocationTrackUpdate(
      accepted: true,
      distanceDelta: delta,
      speed: _speed,
      motionState: LocationMotionState.moving,
    );
  }

  void reset() {
    _anchor = null;
    _lastReliableFixAt = null;
    _lastMovementAt = null;
    _stationaryFixes = 0;
    _distance = 0;
    _speed = 0;
    _elevationGain = 0;
  }

  static double distanceBetween(
    LocationTrackPoint from,
    LocationTrackPoint to,
  ) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLon = _toRadians(to.longitude - from.longitude);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final boundedA = a.clamp(0.0, 1.0);
    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  bool _isValid(LocationTrackPoint point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.altitude.isFinite &&
        point.accuracy.isFinite &&
        point.reportedSpeed.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180 &&
        point.accuracy >= 0;
  }
}
