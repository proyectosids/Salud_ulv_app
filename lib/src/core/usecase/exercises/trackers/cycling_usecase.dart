import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/models/exercise_categories.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/services/error_handlers.dart';
import 'package:salud_ulv_app/src/core/services/exercise_services.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';
import 'package:uuid/uuid.dart';

class CyclingActivityUsecase
    implements IExerciseTrackUseCase, ISpeedTrackable, ILocationTrackable {
  final IExerciseLocalRepo exerciseLocalRepo;
  final IActivitySampleRepo aerobicSampleRepo;
  final ICurrentUserSession currentUserSession;

  final IGeolocator geolocatorSensor;

  CyclingActivityUsecase(
    this.exerciseLocalRepo,
    this.aerobicSampleRepo,
    this.currentUserSession,
    this.geolocatorSensor,
  );

  static const int _categoryID = ExerciseCategoryIds.cycling;

  // MET aproximado para ciclismo a ritmo moderado (~8.0)
  static const double _cyclingMet = 8.0;
  static const double _weightKg = 70;

  final ExerciseTimer _timer = ExerciseTimer();

  static int _instanceCount = 0;
  final int _instanceId = ++_instanceCount;

  String? _activityID;
  String? _userUUID;
  DateTime date = DateTime.now().toUtc();

  String get activityID {
    if (_activityID == null) {
      throw StateError('Activity has not started');
    }
    return _activityID!;
  }

  static const Duration _snapshotInterval = Duration(seconds: 5);

  Timer? _snapshotTimer;
  bool _snapshotBusy = false;
  double _lastSnapshotDistance = 0.0;
  double _lastSnapshotElevation = 0.0;
  double _lastSnapshotCaloriesBurned = 0.0;
  Duration _lastSnapshotElapsed = Duration.zero;

  @override
  Stream<Duration>? get elapsedStream => _timer.stream;

  @override
  Duration? get elapsed => _timer.elapsed;

  @override
  double? get distance => geolocatorSensor.distance;

  @override
  double? get caloriesBurned {
    final e = elapsed;
    if (e == null) return 0;
    return calculateCalories(elapsed: e, weightKg: _weightKg, met: _cyclingMet);
  }

  /// Velocidad instantánea en m/s (GPS).
  @override
  double? get speed => geolocatorSensor.speed;

  /// Velocidad promedio en m/s: distancia total / tiempo transcurrido.
  double get avgSpeed {
    final e = elapsed;
    final d = distance;
    if (e == null || d == null || e.inSeconds == 0) return 0;
    return d / e.inSeconds;
  }

  bool get isPaused => _timer.isPaused;

  @override
  Coordinates? get startLocation {
    final lat = geolocatorSensor.startLatitude;
    final lng = geolocatorSensor.startLongitude;
    if (lat == null || lng == null) return null;
    return Coordinates(latitude: lat, longitude: lng);
  }

  @override
  Coordinates? get currentLocation {
    // latitude/longitude arrancan en 0.0 hasta la primera lectura;
    // usa startLatitude como señal de que ya hay un fix real.
    if (geolocatorSensor.startLatitude == null) return null;
    return Coordinates(
      latitude: geolocatorSensor.latitude,
      longitude: geolocatorSensor.longitude,
    );
  }

  @override
  Future<void> start() async {
    // Los permisos se validan una sola vez en ExerciseTrackingBloc.
    final userUUID = await currentUserSession.getCurrentUserUUID();
    if (userUUID == null) return;

    // 2. Estado limpio
    _activityID = const Uuid().v4().toUpperCase();
    _userUUID = userUUID;
    debugPrint('CyclingID: $activityID');

    _lastSnapshotDistance = 0.0;
    _lastSnapshotElevation = 0.0;
    _lastSnapshotCaloriesBurned = 0.0;
    _lastSnapshotElapsed = Duration.zero;

    // 3. Crear la fila en BD
    await exerciseLocalRepo.setIDs(activityID, userUUID, _categoryID, date);

    await geolocatorSensor.start(3, 4, 1, maxExpectedSpeed: 22);

    _timer.start();
    _startSnapshotTimer();
  }

  @override
  void pause() {
    geolocatorSensor.pause();
    _timer.pause();
    _snapshotTimer?.cancel();
  }

  @override
  void resume() {
    geolocatorSensor.resume();
    _timer.resume();
    _startSnapshotTimer();
  }

  @override
  void reset() {
    // Cancelar el timer primero para que un tick tardío no lea valores reseteados.
    _snapshotTimer?.cancel();
    _snapshotTimer = null;

    geolocatorSensor.reset();
    _timer.reset();
    _lastSnapshotDistance = 0.0;
    _lastSnapshotElevation = 0.0;
    _lastSnapshotCaloriesBurned = 0.0;
    _lastSnapshotElapsed = Duration.zero;
  }

  // ---------------------------------------------------------------------------
  // STOP / DISCARD
  // ---------------------------------------------------------------------------
  Future<void> _stopEverything() async {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _timer.stop();
    geolocatorSensor.stop();
  }

  @override
  Future<void> stopAndSave() async {
    await _stopEverything();
    reset();
  }

  @override
  Future<void> discard() async {
    await _stopEverything();

    // Nada que borrar si start() nunca llegó a crear la fila.
    final id = _activityID;
    if (id != null) {
      try {
        final userUUID =
            _userUUID ?? await currentUserSession.getCurrentUserUUID();
        if (userUUID != null) {
          await exerciseLocalRepo.delete(userUUID, id);
        }
        await aerobicSampleRepo.delete(id);
        debugPrint('cleanup successful ');
      } catch (e) {
        debugPrint('discard() cleanup failed: $e');
      }
    }

    reset();
  }

  @override
  Future<void> save() async {
    pause();

    final currentElapsed = elapsed;
    final currentDistance = distance;

    if (currentElapsed == null ||
        currentElapsed.inSeconds < 10 ||
        currentDistance == null ||
        currentDistance == 0) {
      await discard();
      throw ExerciseValidationException(
        'No es posible guardar actividades menores a 10 segundos o sin distancia recorrida',
      );
    }

    final sampleData = await aerobicSampleRepo.getSamples(activityID);
    if (sampleData == null || sampleData.isEmpty) {
      await discard();
      throw ExerciseValidationException(
        'No hay datos suficientes para guardar esta actividad',
      );
    }

    final paceList = sampleData
        .map((sample) => sample.pace)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    final elevationList = sampleData
        .map((sample) => sample.elevation)
        .whereType<double>()
        .toList();

    final speedList = sampleData
        .map((sample) => sample.speed)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    final elevationGain = elevationList.isEmpty
        ? 0.0
        : totalElevationGain(elevationList);

    // Desnivel positivo promedio por kilómetro (m/km).
    final distanceKm = currentDistance / 1000;
    final avgElevation = distanceKm > 0 ? elevationGain / distanceKm : 0.0;

    debugPrint('Making cycling class');

    final cyclingData = Cycling(
      activityID: activityID,
      duration: currentElapsed,
      distance: currentDistance,
      caloriesBurned: calculateCaloriesBurned(
        currentElapsed,
        _cyclingMet,
        _weightKg,
      ),
      elevationGain: elevationGain,
      avgElevation: avgElevation,
      // Sin sensor de pedaleo (BLE) no hay forma de medir cadencia real.
      avgCadence: 0,
      avgPace: paceList.isEmpty ? 0 : avgCalculator(paceList),
      speed: maxValue(speedList),
      avgSpeed: avgSpeed,
      registeredAt: date,
    );

    debugPrint('Saving cycling');

    await exerciseLocalRepo.save(cyclingData);
    await stopAndSave();
  }

  void _startSnapshotTimer() {
    debugPrint('Starting snapshot timer for instance $_instanceId');
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(_snapshotInterval, (_) => _takeSnapshot());
  }

  Future<void> _takeSnapshot() async {
    if (_snapshotBusy || _activityID == null) return;

    final currentElapsed = elapsed;
    final currentDistance = distance;
    if (currentElapsed == null || currentDistance == null) return;

    final interval = currentElapsed - _lastSnapshotElapsed;
    if (interval.inMilliseconds <= 0) return;

    _snapshotBusy = true;
    try {
      final currentElevation = geolocatorSensor.elevation;

      final currentCalories = calculateCalories(
        elapsed: currentElapsed,
        weightKg: _weightKg,
        met: _cyclingMet,
      );

      // Deltas respecto a los acumulados previos
      final distanceDelta = currentDistance - _lastSnapshotDistance;
      final elevationDelta = currentElevation - _lastSnapshotElevation;
      final caloriesDelta = currentCalories - _lastSnapshotCaloriesBurned;

      // Tasas del intervalo
      final pace = geolocatorSensor.hasMovement
          ? calculatePace(interval, distanceDelta)
          : 0.0;
      final currentSpeed = geolocatorSensor.speed;

      final snapshotData = CyclingActivitySample(
        activityID: activityID,
        timestampMs: currentElapsed,
        distance: distanceDelta,
        calories: caloriesDelta,
        elevation: elevationDelta,
        cadence: 0,
        pace: pace,
        speed: currentSpeed,
        heartRate: 0,
        latitude: geolocatorSensor.latitude,
        longitude: geolocatorSensor.longitude,
      );

      await aerobicSampleRepo.save(snapshotData);

      _lastSnapshotDistance = currentDistance;
      _lastSnapshotElevation = currentElevation;
      _lastSnapshotCaloriesBurned = currentCalories;
      _lastSnapshotElapsed = currentElapsed;

      debugPrint(
        'Snapshot saved: activityID=$activityID '
        'distance=$distanceDelta calories=$caloriesDelta '
        'pace=$pace speed=$currentSpeed elapsed=$currentElapsed',
      );
    } catch (e, st) {
      // Un snapshot fallido nunca debe tumbar la sesión de tracking.
      debugPrint('Snapshot failed: $e\n$st');
    } finally {
      _snapshotBusy = false;
    }
  }
}
