import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/route_points.dart';

void main() {
  WalkActivitySample sample(double? latitude, double? longitude) {
    return WalkActivitySample(
      activityID: 'walk-1',
      timestampMs: Duration.zero,
      latitude: latitude,
      longitude: longitude,
    );
  }

  test('removes missing, zero and duplicate route coordinates', () {
    final points = validRoutePoints([
      sample(null, null),
      sample(0, 0),
      sample(25.676, -100.289),
      sample(25.676, -100.289),
      sample(25.677, -100.288),
    ]);

    expect(points, hasLength(2));
    expect(points.first.latitude, 25.676);
    expect(points.last.longitude, -100.288);
  });

  test('removes coordinates outside geographic bounds', () {
    final points = validRoutePoints([
      sample(91, -100),
      sample(25, -181),
      sample(25, -100),
    ]);

    expect(points, hasLength(1));
  });
}
