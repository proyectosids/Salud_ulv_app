import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/step_fusion_tracker.dart';

void main() {
  final originTime = DateTime.utc(2026, 1, 1, 12);

  test('reliable stationary location vetoes phone-shake candidates', () {
    final tracker = StepFusionTracker();
    var confirmed = 0;

    for (var index = 0; index < 12; index++) {
      confirmed += tracker
          .addCandidate(
            timestamp: originTime.add(Duration(milliseconds: index * 500)),
            motionState: LocationMotionState.stationary,
            detectorConfidence: 1,
          )
          .confirmedSteps;
    }

    expect(confirmed, 0);
  });

  test('releases warmup steps after a coherent moving cadence', () {
    final tracker = StepFusionTracker();
    var confirmed = 0;

    for (var index = 0; index < 5; index++) {
      confirmed += tracker
          .addCandidate(
            timestamp: originTime.add(Duration(milliseconds: index * 550)),
            motionState: LocationMotionState.moving,
            detectorConfidence: 0.85,
          )
          .confirmedSteps;
    }

    expect(confirmed, 5);
  });

  test('requires a longer regular bout when location is unavailable', () {
    final tracker = StepFusionTracker();
    var confirmed = 0;

    for (var index = 0; index < 5; index++) {
      confirmed += tracker
          .addCandidate(
            timestamp: originTime.add(Duration(milliseconds: index * 600)),
            motionState: LocationMotionState.unavailable,
            detectorConfidence: 0.9,
          )
          .confirmedSteps;
    }
    expect(confirmed, 0);

    confirmed += tracker
        .addCandidate(
          timestamp: originTime.add(const Duration(milliseconds: 3000)),
          motionState: LocationMotionState.unavailable,
          detectorConfidence: 0.9,
        )
        .confirmedSteps;
    expect(confirmed, 6);
  });

  test('does not validate an irregular locationless sequence', () {
    final tracker = StepFusionTracker();
    final offsets = [0, 300, 1100, 1420, 2450, 2780];
    var confirmed = 0;

    for (final offset in offsets) {
      confirmed += tracker
          .addCandidate(
            timestamp: originTime.add(Duration(milliseconds: offset)),
            motionState: LocationMotionState.unavailable,
            detectorConfidence: 0.9,
          )
          .confirmedSteps;
    }

    expect(confirmed, 0);
  });
}
