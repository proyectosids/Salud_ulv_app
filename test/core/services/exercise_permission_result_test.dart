import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';

void main() {
  test('granted result allows exercise without a settings action', () {
    const result = ExercisePermissionResult.granted();

    expect(result.isGranted, isTrue);
    expect(result.canOpenSettings, isFalse);
    expect(result.message, isEmpty);
  });

  test('permanent denial exposes recovery through app settings', () {
    const result = ExercisePermissionResult.denied(
      ExercisePermissionIssue.locationPermanentlyDenied,
    );

    expect(result.isGranted, isFalse);
    expect(result.canOpenSettings, isTrue);
    expect(result.message, contains('ajustes'));
  });

  test('a disabled location service opens device location settings', () {
    const result = ExercisePermissionResult.denied(
      ExercisePermissionIssue.locationServicesDisabled,
    );

    expect(result.isGranted, isFalse);
    expect(result.canOpenSettings, isTrue);
  });

  test('a permission already requested can recover through app settings', () {
    const result = ExercisePermissionResult.denied(
      ExercisePermissionIssue.locationPreviouslyDenied,
    );

    expect(result.isGranted, isFalse);
    expect(result.canOpenSettings, isTrue);
    expect(result.message, contains('ya fue solicitado'));
  });

  test('activity recognition denial can recover through app settings', () {
    const result = ExercisePermissionResult.denied(
      ExercisePermissionIssue.activityRecognitionPreviouslyDenied,
    );

    expect(result.isGranted, isFalse);
    expect(result.canOpenSettings, isTrue);
    expect(result.message, contains('actividad física'));
  });
}
