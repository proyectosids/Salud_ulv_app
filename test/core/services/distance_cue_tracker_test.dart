import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/services/exercise_audio_cue_service.dart';

void main() {
  group('DistanceCueTracker', () {
    test('announces each configured kilometre only once', () {
      final tracker = DistanceCueTracker(intervalMeters: 1000);

      expect(
        tracker.update(
          distanceMeters: 999,
          elapsed: const Duration(minutes: 6),
        ),
        isNull,
      );
      final first = tracker.update(
        distanceMeters: 1002,
        elapsed: const Duration(minutes: 6, seconds: 10),
      );
      expect(first?.distanceMeters, 1000);
      expect(first?.splitDuration, const Duration(minutes: 6, seconds: 10));
      expect(
        tracker.update(
          distanceMeters: 1100,
          elapsed: const Duration(minutes: 7),
        ),
        isNull,
      );
    });

    test('supports 500 metre splits and calculates split pace', () {
      final tracker = DistanceCueTracker(intervalMeters: 500);

      final first = tracker.update(
        distanceMeters: 510,
        elapsed: const Duration(minutes: 3),
      );
      final second = tracker.update(
        distanceMeters: 1005,
        elapsed: const Duration(minutes: 5, seconds: 45),
      );

      expect(first?.distanceMeters, 500);
      expect(first?.paceSecondsPerKm, 360);
      expect(second?.distanceMeters, 1000);
      expect(second?.splitDuration, const Duration(minutes: 2, seconds: 45));
      expect(second?.paceSecondsPerKm, 330);
    });
  });
}
