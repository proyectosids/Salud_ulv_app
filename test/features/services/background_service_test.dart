import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/features/services/background_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('background exercise service is disabled safely on Windows', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    expect(isBackgroundServiceSupported, isFalse);
    await expectLater(initializeService(), completes);
    await expectLater(startBackgroundService(), completes);
    expect(stopBackgroundService, returnsNormally);
    expect(startExerciseTracking, returnsNormally);
    expect(pauseExerciseTracking, returnsNormally);
    expect(stopExerciseTracking, returnsNormally);
    expect(finishExercise, returnsNormally);
  });

  test('background exercise service remains enabled for mobile targets', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(isBackgroundServiceSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(isBackgroundServiceSupported, isTrue);
  });
}
