import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';

void main() {
  final originTime = DateTime.utc(2026, 1, 1, 12);

  LocationTrackPoint point({
    required double latitude,
    required DateTime timestamp,
    double longitude = -99.1332,
    double accuracy = 5,
    double speed = 0,
  }) {
    return LocationTrackPoint(
      latitude: latitude,
      longitude: longitude,
      altitude: 2240,
      accuracy: accuracy,
      timestamp: timestamp,
      reportedSpeed: speed,
    );
  }

  test('does not turn stationary GPS drift into travelled distance', () {
    final filter = LocationTrackFilter(
      minimumDisplacement: 1,
      maximumAccuracy: 25,
      maximumSpeed: 3.2,
    );
    const latitude = 19.4326;
    filter.update(point(latitude: latitude, timestamp: originTime));

    for (var index = 1; index <= 8; index++) {
      final oneMeterJitter = index.isEven ? 0.000008 : -0.000008;
      filter.update(
        point(
          latitude: latitude + oneMeterJitter,
          timestamp: originTime.add(Duration(seconds: index)),
        ),
      );
    }

    expect(filter.distance, 0);
    expect(
      filter.motionStateAt(originTime.add(const Duration(seconds: 8))),
      LocationMotionState.stationary,
    );
  });

  test('accepts plausible movement and accumulates a filtered distance', () {
    final filter = LocationTrackFilter(
      minimumDisplacement: 1,
      maximumAccuracy: 25,
      maximumSpeed: 3.2,
    );
    const latitude = 19.4326;
    filter.update(point(latitude: latitude, timestamp: originTime));
    filter.update(
      point(
        latitude: latitude + 0.00009,
        timestamp: originTime.add(const Duration(seconds: 6)),
        speed: 1.6,
      ),
    );

    expect(filter.distance, inInclusiveRange(9, 11));
    expect(
      filter.motionStateAt(originTime.add(const Duration(seconds: 6))),
      LocationMotionState.moving,
    );
  });

  test('rejects poor accuracy and impossible jumps', () {
    final filter = LocationTrackFilter(
      minimumDisplacement: 1,
      maximumAccuracy: 25,
      maximumSpeed: 3.2,
    );
    const latitude = 19.4326;
    filter.update(point(latitude: latitude, timestamp: originTime));

    filter.update(
      point(
        latitude: latitude + 0.001,
        accuracy: 80,
        timestamp: originTime.add(const Duration(seconds: 2)),
      ),
    );
    filter.update(
      point(
        latitude: latitude + 0.001,
        timestamp: originTime.add(const Duration(seconds: 3)),
      ),
    );

    expect(filter.distance, 0);
  });
}
