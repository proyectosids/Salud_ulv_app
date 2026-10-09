import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/hybrid_step_tracker.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';

PlatformStepReading nativeReading({
  int confirmed = 0,
  int? live,
  bool counter = true,
  bool detector = true,
}) => PlatformStepReading(
  counterAvailable: counter,
  detectorAvailable: detector,
  confirmedSteps: confirmed,
  liveSteps: live ?? confirmed,
);

void main() {
  test(
    'does not accept native steps while a reliable GPS fix is stationary',
    () {
      final tracker = HybridStepTracker()
        ..updatePlatformReading(nativeReading(confirmed: 20));

      expect(
        tracker.resolve(
          distanceMeters: 0,
          motionState: LocationMotionState.stationary,
        ),
        0,
      );
    },
  );

  test('uses native session steps while movement is established', () {
    final tracker = HybridStepTracker()
      ..updatePlatformReading(nativeReading(confirmed: 120));

    expect(
      tracker.resolve(
        distanceMeters: 50,
        motionState: LocationMotionState.moving,
      ),
      120,
    );
  });

  test('derives a conservative non-zero floor from filtered GPS distance', () {
    final tracker = HybridStepTracker();

    expect(
      tracker.resolve(
        distanceMeters: 50,
        motionState: LocationMotionState.moving,
      ),
      69,
    );
  });

  test('personalizes fallback step length from the user height', () {
    final taller = HybridStepTracker()..configureHeightCm(172);
    final shorter = HybridStepTracker()..configureHeightCm(150);

    expect(taller.estimatedStepLengthMeters, closeTo(0.710, 0.001));
    expect(shorter.estimatedStepLengthMeters, closeTo(0.620, 0.001));
    expect(
      shorter.resolve(
        distanceMeters: 50,
        motionState: LocationMotionState.moving,
      ),
      greaterThan(
        taller.resolve(
          distanceMeters: 50,
          motionState: LocationMotionState.moving,
        ),
      ),
    );
  });

  test('uses the safe default when height is missing or invalid', () {
    final tracker = HybridStepTracker()..configureHeightCm(0);

    expect(tracker.estimatedStepLengthMeters, 0.72);
  });

  test('combines height and GPS speed for a slow walking fallback', () {
    final tracker = HybridStepTracker()..configureHeightCm(172);

    final steps = tracker.resolve(
      distanceMeters: 40,
      walkingSpeedMetersPerSecond: 40 / 59,
      motionState: LocationMotionState.moving,
    );

    expect(steps, inInclusiveRange(78, 80));
  });

  test('does not add steps while distance remains fixed after stopping', () {
    final tracker = HybridStepTracker()..configureHeightCm(172);
    final walkingSteps = tracker.resolve(
      distanceMeters: 830,
      walkingSpeedMetersPerSecond: 1.1,
      motionState: LocationMotionState.moving,
    );

    for (var second = 0; second < 300; second++) {
      expect(
        tracker.resolve(
          distanceMeters: 830,
          walkingSpeedMetersPerSecond: 0,
          motionState: LocationMotionState.stationary,
        ),
        walkingSteps,
      );
    }
  });

  test('does not convert stationary GPS drift into additional steps', () {
    final tracker = HybridStepTracker()..configureHeightCm(172);
    final walkingSteps = tracker.resolve(
      distanceMeters: 100,
      walkingSpeedMetersPerSecond: 1,
      motionState: LocationMotionState.moving,
    );

    final afterDrift = tracker.resolve(
      distanceMeters: 112,
      walkingSpeedMetersPerSecond: 0,
      motionState: LocationMotionState.stationary,
    );

    expect(afterDrift, walkingSteps);
  });

  test('accepts a final counter batch inside the delivery grace period', () {
    final tracker = HybridStepTracker();
    final startedAt = DateTime(2026, 10, 8, 10);
    tracker.updatePlatformReading(nativeReading(confirmed: 80));
    final whileMoving = tracker.resolve(
      distanceMeters: 50,
      walkingSpeedMetersPerSecond: 1,
      motionState: LocationMotionState.moving,
      timestamp: startedAt,
    );

    tracker.updatePlatformReading(nativeReading(confirmed: 95));
    final whileStopped = tracker.resolve(
      distanceMeters: 50,
      walkingSpeedMetersPerSecond: 0,
      motionState: LocationMotionState.stationary,
      timestamp: startedAt.add(const Duration(seconds: 8)),
    );

    expect(whileMoving, 80);
    expect(whileStopped, 95);
  });

  test('discards native increments received long after stopping', () {
    final tracker = HybridStepTracker();
    final startedAt = DateTime(2026, 10, 8, 10);
    tracker.updatePlatformReading(nativeReading(confirmed: 80));
    final whileMoving = tracker.resolve(
      distanceMeters: 50,
      walkingSpeedMetersPerSecond: 1,
      motionState: LocationMotionState.moving,
      timestamp: startedAt,
    );

    tracker.updatePlatformReading(nativeReading(confirmed: 95));
    final longAfterStopping = tracker.resolve(
      distanceMeters: 50,
      walkingSpeedMetersPerSecond: 0,
      motionState: LocationMotionState.stationary,
      timestamp: startedAt.add(const Duration(seconds: 30)),
    );

    expect(longAfterStopping, whileMoving);
  });

  test('native pedometer prevents GPS estimation from inflating steps', () {
    final tracker = HybridStepTracker()
      ..configureHeightCm(172)
      ..updatePlatformReading(nativeReading(confirmed: 1169));

    final steps = tracker.resolve(
      distanceMeters: 830,
      walkingSpeedMetersPerSecond: 0.55,
      motionState: LocationMotionState.moving,
    );

    expect(steps, 1169);
  });

  test('step detector advances the live value without adding both sources', () {
    final tracker = HybridStepTracker()
      ..updatePlatformReading(nativeReading(confirmed: 50, live: 51));

    expect(
      tracker.resolve(
        distanceMeters: 35,
        motionState: LocationMotionState.moving,
      ),
      51,
    );
  });

  test('calibrates step length slowly from reliable native and GPS data', () {
    final tracker = HybridStepTracker()
      ..configureHeightCm(172)
      ..updatePlatformReading(nativeReading(confirmed: 150));

    tracker.resolve(
      distanceMeters: 100,
      walkingSpeedMetersPerSecond: 1,
      motionState: LocationMotionState.moving,
    );

    expect(tracker.hasSessionCalibration, isTrue);
    expect(tracker.estimatedStepLengthMeters, closeTo(0.7035, 0.001));
  });

  test('discarded paused readings do not appear after resuming', () {
    final tracker = HybridStepTracker()
      ..updatePlatformReading(nativeReading(confirmed: 20, live: 20));
    final beforePause = tracker.resolve(
      distanceMeters: 15,
      motionState: LocationMotionState.moving,
    );

    tracker.discardPlatformReading(nativeReading(confirmed: 35, live: 35));
    final afterResume = tracker.resolve(
      distanceMeters: 16,
      motionState: LocationMotionState.moving,
    );

    expect(beforePause, 20);
    expect(afterResume, 20);
  });

  test('uses accelerometer fallback when it has the strongest evidence', () {
    final tracker = HybridStepTracker()..addAccelerometerSteps(42);

    expect(
      tracker.resolve(
        distanceMeters: 10,
        motionState: LocationMotionState.moving,
      ),
      42,
    );
  });
}
