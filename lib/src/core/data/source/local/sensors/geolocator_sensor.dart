import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';

class GeolocatorSensor implements IGeolocator {
  StreamSubscription<Position>? _subscription;
  LocationTrackFilter? _filter;

  double _latitude = 0;
  double _longitude = 0;
  double? _startLatitude;
  double? _startLongitude;

  @override
  double get speed => _filter?.speed ?? 0;

  @override
  double get distance => _filter?.distance ?? 0;

  @override
  double get latitude => _latitude;

  @override
  double get longitude => _longitude;

  @override
  double get elevation => _filter?.elevationGain ?? 0;

  @override
  bool get hasMovement =>
      _filter?.motionStateAt(DateTime.now()) == LocationMotionState.moving;

  @override
  bool get hasReliableFix => _filter?.hasReliableFixAt(DateTime.now()) ?? false;

  @override
  double? get startLatitude => _startLatitude;

  @override
  double? get startLongitude => _startLongitude;

  LocationAccuracy setAccuracyLevel(int accuracyLevel) {
    switch (accuracyLevel) {
      case 1:
        return LocationAccuracy.lowest;
      case 2:
        return LocationAccuracy.low;
      case 3:
        return LocationAccuracy.medium;
      case 4:
        return LocationAccuracy.high;
      default:
        return LocationAccuracy.best;
    }
  }

  @override
  Future<Coordinates?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      // A cached position can belong to a previous trip and must never be used
      // as the origin of a new exercise. The map remains available offline
      // while the live tracking stream waits for a fresh GPS fix.
      return null;
    }

    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(seconds: 30) || position.accuracy > 45) {
      return null;
    }
    return Coordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<void> start(
    double minMovementDistance,
    int accuracyLevel,
    int distanceFilter, {
    double maxExpectedSpeed = 15,
  }) async {
    await _subscription?.cancel();
    _filter = LocationTrackFilter(
      minimumDisplacement: minMovementDistance,
      maximumAccuracy: 25,
      maximumSpeed: maxExpectedSpeed,
    );
    final stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: setAccuracyLevel(accuracyLevel),
        distanceFilter: distanceFilter,
      ),
    );
    _subscription = stream.listen(_onPosition);
  }

  void _onPosition(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(seconds: 20)) return;

    final update = _filter?.update(
      LocationTrackPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
        reportedSpeed: position.speed,
      ),
    );
    if (update?.accepted != true) return;

    // Expose and persist only coordinates accepted by the accuracy/speed
    // filter. Raw fixes can temporarily be (0, 0), stale, or impossible jumps.
    _startLatitude ??= position.latitude;
    _startLongitude ??= position.longitude;
    _latitude = position.latitude;
    _longitude = position.longitude;
  }

  @override
  void pause() => _subscription?.pause();

  @override
  void resume() => _subscription?.resume();

  @override
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void reset() {
    _filter?.reset();
    _filter = null;
    _latitude = 0;
    _longitude = 0;
    _startLatitude = null;
    _startLongitude = null;
  }
}
