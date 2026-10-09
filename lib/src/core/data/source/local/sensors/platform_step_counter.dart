import 'package:flutter/services.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';

class PlatformStepCounter implements IPlatformStepCounter {
  const PlatformStepCounter();

  static const _channel = EventChannel('com.azaiulv.salud_ulv_app/steps');

  @override
  Stream<PlatformStepReading> get sessionSteps =>
      _channel.receiveBroadcastStream().map(_readingFromPlatformEvent);

  PlatformStepReading _readingFromPlatformEvent(Object? event) {
    // Backward-compatible parsing keeps hot-reload/dev sessions from failing
    // if the Dart side reconnects before the native app has been reinstalled.
    if (event is num) {
      final steps = event.round();
      return PlatformStepReading(
        counterAvailable: true,
        detectorAvailable: false,
        confirmedSteps: steps,
        liveSteps: steps,
      );
    }

    if (event is! Map) {
      throw const FormatException('Invalid native step counter value');
    }

    final confirmed = (event['confirmedSteps'] as num?)?.round() ?? 0;
    final live = (event['liveSteps'] as num?)?.round() ?? confirmed;
    return PlatformStepReading(
      counterAvailable: event['counterAvailable'] == true,
      detectorAvailable: event['detectorAvailable'] == true,
      confirmedSteps: confirmed.clamp(0, 1 << 31),
      liveSteps: live.clamp(0, 1 << 31),
    );
  }
}
