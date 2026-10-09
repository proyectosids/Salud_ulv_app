import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/step_fusion_tracker.dart';
import 'package:salud_ulv_app/src/core/services/step_counter.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';

void main() {
  final origin = DateTime.utc(2026, 1, 1, 12);
  const latitude = 19.4326;

  final detector = StepDetector();
  for (var index = 0; index < StepDetector.calibrationSamples; index++) {
    detector.update([0, 0, 0], timestamp: origin);
  }
  _expect(
    detector.state == StepDetectorState.idle,
    'step detector did not complete deterministic calibration',
  );
  _expect(
    !detector.update([double.nan, 0, 0], timestamp: origin),
    'non-finite accelerometer data produced a step',
  );
  _expect(
    detector.baseline.isFinite && detector.threshold.isFinite,
    'non-finite accelerometer data poisoned detector calibration',
  );

  const deniedPermission = ExercisePermissionResult.denied(
    ExercisePermissionIssue.locationPermanentlyDenied,
  );
  _expect(
    !deniedPermission.isGranted && deniedPermission.canOpenSettings,
    'permanent permission denial has no recovery path',
  );
  const previouslyDeniedPermission = ExercisePermissionResult.denied(
    ExercisePermissionIssue.locationPreviouslyDenied,
  );
  _expect(
    previouslyDeniedPermission.canOpenSettings,
    'a previously requested permission has no settings recovery path',
  );

  LocationTrackPoint point(
    double lat,
    Duration offset, {
    double accuracy = 5,
    double speed = 0,
  }) {
    return LocationTrackPoint(
      latitude: lat,
      longitude: -99.1332,
      altitude: 2240,
      accuracy: accuracy,
      timestamp: origin.add(offset),
      reportedSpeed: speed,
    );
  }

  final stationary = LocationTrackFilter(
    minimumDisplacement: 1,
    maximumAccuracy: 25,
    maximumSpeed: 3.2,
  );
  stationary.update(point(latitude, Duration.zero));
  for (var index = 1; index <= 8; index++) {
    final jitter = index.isEven ? 0.000008 : -0.000008;
    stationary.update(point(latitude + jitter, Duration(seconds: index)));
  }
  _expect(stationary.distance == 0, 'stationary drift added distance');

  final walking = LocationTrackFilter(
    minimumDisplacement: 1,
    maximumAccuracy: 25,
    maximumSpeed: 3.2,
  );
  walking.update(point(latitude, Duration.zero));
  walking.update(
    point(latitude + 0.00009, const Duration(seconds: 6), speed: 1.6),
  );
  _expect(
    walking.distance >= 9 && walking.distance <= 11,
    'plausible walking distance was rejected',
  );

  final rejectedGps = LocationTrackFilter(
    minimumDisplacement: 1,
    maximumAccuracy: 25,
    maximumSpeed: 3.2,
  );
  rejectedGps.update(point(latitude, Duration.zero));
  rejectedGps.update(
    point(latitude + 0.001, const Duration(seconds: 2), accuracy: 80),
  );
  rejectedGps.update(point(latitude + 0.001, const Duration(seconds: 3)));
  _expect(rejectedGps.distance == 0, 'invalid GPS jump added distance');

  final stationaryFusion = StepFusionTracker();
  var stationarySteps = 0;
  for (var index = 0; index < 12; index++) {
    stationarySteps += stationaryFusion
        .addCandidate(
          timestamp: origin.add(Duration(milliseconds: index * 500)),
          motionState: LocationMotionState.stationary,
          detectorConfidence: 1,
        )
        .confirmedSteps;
  }
  _expect(stationarySteps == 0, 'stationary phone movement produced steps');

  final movingFusion = StepFusionTracker();
  var movingSteps = 0;
  for (var index = 0; index < 5; index++) {
    movingSteps += movingFusion
        .addCandidate(
          timestamp: origin.add(Duration(milliseconds: index * 550)),
          motionState: LocationMotionState.moving,
          detectorConfidence: 0.85,
        )
        .confirmedSteps;
  }
  _expect(movingSteps == 5, 'coherent moving cadence lost steps');

  final locationlessFusion = StepFusionTracker();
  var locationlessSteps = 0;
  for (var index = 0; index < 5; index++) {
    locationlessSteps += locationlessFusion
        .addCandidate(
          timestamp: origin.add(Duration(milliseconds: index * 600)),
          motionState: LocationMotionState.unavailable,
          detectorConfidence: 0.9,
        )
        .confirmedSteps;
  }
  _expect(locationlessSteps == 0, 'locationless warmup was too permissive');
  locationlessSteps += locationlessFusion
      .addCandidate(
        timestamp: origin.add(const Duration(milliseconds: 3000)),
        motionState: LocationMotionState.unavailable,
        detectorConfidence: 0.9,
      )
      .confirmedSteps;
  _expect(locationlessSteps == 6, 'locationless regular bout was rejected');
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
