import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';

/// Keeps a recent, validated GPS fix available while the app is open.
///
/// The value is intentionally not persisted: a coordinate from a previous app
/// session could belong to a different trip and must not become the origin of
/// a new activity.
class CurrentLocationCache {
  CurrentLocationCache._();

  static final CurrentLocationCache instance = CurrentLocationCache._();

  static const Duration _maximumAge = Duration(minutes: 3);

  Coordinates? _coordinates;
  DateTime? _updatedAt;
  Future<Coordinates?>? _warmUpInProgress;

  Coordinates? get current {
    final coordinates = _coordinates;
    final updatedAt = _updatedAt;
    if (coordinates == null || updatedAt == null) return null;
    if (DateTime.now().difference(updatedAt) > _maximumAge) return null;
    return coordinates;
  }

  void update(Coordinates coordinates) {
    _coordinates = coordinates;
    _updatedAt = DateTime.now();
  }

  /// Starts one non-blocking GPS lookup as soon as the authenticated shell is
  /// shown. It does not ask for permissions outside the existing exercise
  /// flow; when permission already exists, the activity map can open directly
  /// at the user's position.
  Future<Coordinates?> warmUp(IGeolocator geolocator) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return Future.value(null);
    }

    final cached = current;
    if (cached != null) return Future.value(cached);

    return _warmUpInProgress ??= _load(geolocator).whenComplete(() {
      _warmUpInProgress = null;
    });
  }

  Future<Coordinates?> _load(IGeolocator geolocator) async {
    try {
      final coordinates = await geolocator.getCurrentLocation();
      if (coordinates != null) update(coordinates);
      return coordinates;
    } catch (error) {
      debugPrint('No se pudo precargar la ubicación actual: $error');
      return null;
    }
  }
}
