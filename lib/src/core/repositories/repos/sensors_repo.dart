// abstract class ISensorsRepo {
//   Future<void> start();
//   void pause();
//   void resume();
//   void stop();
//   void reset();
// }

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});
}

abstract class IAccelerometer {
  Stream<List<double>?> get magnitude;

  Future<void> start();
  void pause();
  void resume();
  void stop();
  void reset();
}

class PlatformStepReading {
  final bool counterAvailable;
  final bool detectorAvailable;
  final int confirmedSteps;
  final int liveSteps;

  const PlatformStepReading({
    required this.counterAvailable,
    required this.detectorAvailable,
    required this.confirmedSteps,
    required this.liveSteps,
  });

  bool get hasNativeSensor => counterAvailable || detectorAvailable;
}

/// Session-relative readings reported by the operating-system pedometer.
///
/// [confirmedSteps] comes from the more accurate cumulative counter, while
/// [liveSteps] may be advanced by the lower-latency step detector. They are two
/// views of the same walk and must never be added together.
abstract class IPlatformStepCounter {
  Stream<PlatformStepReading> get sessionSteps;
}

abstract class IStepCalibrationRepo {
  Future<double?> loadStepLengthMeters(String userUUID);
  Future<void> saveStepLengthMeters(String userUUID, double meters);
}

abstract class IGeolocator {
  double get distance;
  double get latitude;
  double get longitude;
  double get speed;
  double get elevation;
  bool get hasMovement;
  bool get hasReliableFix;

  double? get startLatitude;
  double? get startLongitude;

  Future<Coordinates?> getCurrentLocation();

  Future<void> start(
    double minMovementDistance,
    int accuracyLevel,
    int distanceFilter, {
    double maxExpectedSpeed = 15,
  });
  void pause();
  void resume();
  void stop();
  void reset();
}
