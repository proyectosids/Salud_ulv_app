import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExercisePermissionService implements IExercisePermissionService {
  static const _locationPromptedKey =
      'exercise_location_permission_prompted_v1';
  static const _notificationPromptedKey =
      'exercise_notification_permission_prompted_v1';
  static const _activityPromptedKey =
      'exercise_activity_permission_prompted_v1';

  Future<ExercisePermissionResult>? _activeRequest;

  @override
  Future<ExercisePermissionResult> check({bool requiresLocation = true}) async {
    if (requiresLocation) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ExercisePermissionResult.denied(
          ExercisePermissionIssue.locationServicesDisabled,
        );
      }

      final location = _mapLocationPermission(
        await Geolocator.checkPermission(),
      );
      if (!location.isGranted) return location;
    }
    return _checkActivityRecognition();
  }

  Future<ExercisePermissionResult> _requestLocationWhenNeeded() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const ExercisePermissionResult.denied(
        ExercisePermissionIssue.locationServicesDisabled,
      );
    }

    var location = _mapLocationPermission(await Geolocator.checkPermission());
    if (location.isGranted ||
        location.issue != ExercisePermissionIssue.locationDenied) {
      return location;
    }

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_locationPromptedKey) ?? false) {
      return const ExercisePermissionResult.denied(
        ExercisePermissionIssue.locationPreviouslyDenied,
      );
    }

    // Register before opening the system dialog so an app suspension cannot
    // launch a duplicate permission prompt.
    await preferences.setBool(_locationPromptedKey, true);
    location = _mapLocationPermission(await Geolocator.requestPermission());
    if (location.issue == ExercisePermissionIssue.locationDenied) {
      return const ExercisePermissionResult.denied(
        ExercisePermissionIssue.locationPreviouslyDenied,
      );
    }
    return location;
  }

  @override
  Future<ExercisePermissionResult> requestWhenNeeded({
    bool requiresLocation = true,
  }) {
    return _activeRequest ??= _requestWhenNeeded(requiresLocation).whenComplete(
      () {
        _activeRequest = null;
      },
    );
  }

  Future<ExercisePermissionResult> _requestWhenNeeded(
    bool requiresLocation,
  ) async {
    if (requiresLocation) {
      final location = await _requestLocationWhenNeeded();
      if (!location.isGranted) return location;
    }

    final activityRecognition = await _requestAndroidActivityRecognitionOnce();
    if (!activityRecognition.isGranted) return activityRecognition;

    await _requestAndroidNotificationOnce();
    return const ExercisePermissionResult.granted();
  }

  Future<ExercisePermissionResult> _checkActivityRecognition() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const ExercisePermissionResult.granted();
    }

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return const ExercisePermissionResult.granted();
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const ExercisePermissionResult.denied(
        ExercisePermissionIssue.activityRecognitionPermanentlyDenied,
      );
    }

    final preferences = await SharedPreferences.getInstance();
    return ExercisePermissionResult.denied(
      preferences.getBool(_activityPromptedKey) ?? false
          ? ExercisePermissionIssue.activityRecognitionPreviouslyDenied
          : ExercisePermissionIssue.activityRecognitionDenied,
    );
  }

  Future<ExercisePermissionResult>
  _requestAndroidActivityRecognitionOnce() async {
    final current = await _checkActivityRecognition();
    if (current.isGranted ||
        current.issue != ExercisePermissionIssue.activityRecognitionDenied) {
      return current;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_activityPromptedKey, true);
    final requested = await Permission.activityRecognition.request();
    if (requested.isGranted) {
      return const ExercisePermissionResult.granted();
    }
    if (requested.isPermanentlyDenied || requested.isRestricted) {
      return const ExercisePermissionResult.denied(
        ExercisePermissionIssue.activityRecognitionPermanentlyDenied,
      );
    }
    return const ExercisePermissionResult.denied(
      ExercisePermissionIssue.activityRecognitionPreviouslyDenied,
    );
  }

  Future<void> _requestAndroidNotificationOnce() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final status = await Permission.notification.status;
    if (status.isGranted || status.isPermanentlyDenied) return;

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_notificationPromptedKey) ?? false) return;

    await preferences.setBool(_notificationPromptedKey, true);
    await Permission.notification.request();
  }

  @override
  Future<bool> openSettingsFor(ExercisePermissionIssue issue) {
    return switch (issue) {
      ExercisePermissionIssue.locationServicesDisabled =>
        Geolocator.openLocationSettings(),
      ExercisePermissionIssue.locationPreviouslyDenied =>
        Geolocator.openAppSettings(),
      ExercisePermissionIssue.locationPermanentlyDenied =>
        Geolocator.openAppSettings(),
      ExercisePermissionIssue.activityRecognitionPreviouslyDenied =>
        openAppSettings(),
      ExercisePermissionIssue.activityRecognitionPermanentlyDenied =>
        openAppSettings(),
      _ => Future.value(false),
    };
  }

  ExercisePermissionResult _mapLocationPermission(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => const ExercisePermissionResult.granted(),
      LocationPermission.deniedForever => const ExercisePermissionResult.denied(
        ExercisePermissionIssue.locationPermanentlyDenied,
      ),
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        const ExercisePermissionResult.denied(
          ExercisePermissionIssue.locationDenied,
        ),
    };
  }
}
